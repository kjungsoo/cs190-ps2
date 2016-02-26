//
//  CPUState.swift
//  Counter
//
//  Created by Brian Hill github.com/brianhill on 2/12/16.
//

// CPUState defines the various CPU registers we need to simulate an HP-35.
//
// This reference is the most thorough, but at the moment a bunch of the image links are broken:
//
// http://home.citycable.ch/pierrefleur/Jacques-Laporte/A&R.htm
//
// This reference is sufficient:
//
// http://www.hpmuseum.org/techcpu.htm

import Foundation

typealias Nibble = UInt8 // This should be UInt4, but the smallest width unsigned integer Swift has is UInt8.

typealias Pointer = UInt8 // Also should be UInt4. In any case, we are not currently using this or Status.

typealias Status = UInt16 // Should be a UInt12 if we wanted exactly as many status bits as the HP-35.

// This is how many nibbles there are in a register:
let RegisterLength = 14

// This is how many of the nibbles are devoted to the exponent:
let ExponentLength = 3

// Two utilities for testing and display:
func nibbleFromCharacter(char: Character) -> Nibble {
    return Nibble(Int(String(char))!)
}

func hexCharacterFromNibble(nibble: Nibble) -> Character {
    return Character(String(format:"%1X", nibble))
}

// A register is 14 nibbles (56 bits). Mostly nibbles are used to represent the digits 0-9, but the leftmost one, nibble 13, corresponds to the sign of the mantissa, nibbles 12 to 3 inclusive represent 10 digits of mantissa, and nibbles 2 to 0 represent the exponent.
struct Register {
    var nibbles: [Nibble] = [Nibble](count:RegisterLength, repeatedValue: UInt8(0))
    
    // Hmmm. It seems I need the empty initializer because I created init(fromDecimalString:).
    init() {}
    
    // Initialize a register from a fourteen-digit decimal string (e.g., "91250000000902")
    init(fromDecimalString: String) {
        let characters = Array(fromDecimalString.characters)
        assert(RegisterLength == characters.count)
        var characterIdx = 0
        var nibbleIdx = RegisterLength - 1
        while nibbleIdx >= 0 {
            let char: Character = characters[characterIdx]
            nibbles[nibbleIdx] = nibbleFromCharacter(char)
            characterIdx += 1
            nibbleIdx -= 1
        }
    }
    
    func asDecimalString() -> String {
        var digits: String = ""
        var nibbleIdx = RegisterLength - 1
        while nibbleIdx >= 0 {
            let nibble = nibbles[nibbleIdx]
            let hexChar = hexCharacterFromNibble(nibble)
            digits.append(hexChar)
            nibbleIdx -= 1
        }
        return digits 
    }
    
    mutating func setNibble(index: Int, value: Nibble) {
        nibbles[index] = value
    }
}

class CPUState {
    
    // The singleton starts in the traditional state that an HP-35 is in when you power it on.
    // The display just shows 0 and a decimal point.
    static let sharedInstance = CPUState(decimalStringA: "00000000000000", decimalStringB: "02999999999999")
    
    var registers = [Register](count:7, repeatedValue:Register())
    
    // All the important initialization is done above when registers is assigned.
    init() {}
    
    // A method provided prinicipally for testing. Allows the state of the registers that record user input to be
    // initialized from decimal strings. Register C will be canonicalized from registers A and B. The remaining
    // registers will be initialized to zeros.
    init(decimalStringA: String, decimalStringB: String) {
        let registerA = Register(fromDecimalString: decimalStringA)
        let registerB = Register(fromDecimalString: decimalStringB)
        
        registers[RegId.A.rawValue] = registerA
        registers[RegId.B.rawValue] = registerB
        
        canonicalize()
    }
    
    // Computes and stores into register C whatever is currently showing to the user in A and B. Note that it
    // is possible for canonicalization to fail. For example 123.4567890 99 overflows when canonicalized. When it
    // fails due to overflow (or underflow), registers A and B are overwritten with overflow (or underflow) values.
    //
    // This function is unimplemented. I hard-coded in a value that will make the first of the five test cases pass.
    //
    // When you are done re-implementing this method, all five test cases should pass (and any other test cases
    // that obey the rules described in comments at the top of DisplayDecoder.swift should also pass).
    //
    // Make use of the enums RegisterASpecialValues and RegisterBSpecialValues so that you don't have to hard
    // code "2" to mean a decimal point (similarly for the other special values).
    func canonicalize() {
        
        //This function was implemented by: 
        //(1) First using register A and register B to determine the exponent for register C. This was done by
        //finding how many positions the decimal must be moved to be on the same position of the first non-zero
        //digit in register A (counting from the left). If the decimal was on the left of the first non-zero,
        //then the difference was negative, if the decimal was on the right of the first non-zero,
        //then the differene was positive. Depending on the various cases (i.e. the exponent stored in register A
        //was originally negative/positive; if it remained negative/positive after adding the difference; etc)
        //the exponents were 'saved' as a string in the form "9##" or "0##" where the #'s represented the
        //exponent and 9/0 were the sign of the exponent.
        //(2) Register B was then used to fill in register C with 0's for every 9 that were in register B
        //This was done by adding the string format of register C to the string "0". Register A was then used
        //to fill in register C with significant digits by saving the position of the last 9 in register B.
        //(3) Register C is then saved as a list of 14 digits which (if there are non-zero numbers) is then
        //sorted so that the first non-zero number is in the first digit position (index 12). This is then
        //stored into the list of registers.
        
        let registerA = registers[RegId.A.rawValue]
        let registerB = registers[RegId.B.rawValue]
        var registerC: Register
        
        let minus = RegisterASpecialValues.Minus.rawValue
        let blank = RegisterBSpecialValues.Blank.rawValue
        let empty = RegisterCSpecialValues.Empty.rawValue
        let point = RegisterBSpecialValues.Point.rawValue
        
        let exponent = registerA.nibbles[0] + registerA.nibbles[1] * 10
        var exponentValue = Int(exponent)
        var negexponentValue: Int = 0
        var decimalStringforRegC: String = ""
        
        var registerB_decimalIndex = 0
        var registerAnonzeroIndex: Int? = 0
        var noNonzeroNumber = false
        var adjustDecimal: Int
        var sigfig = 0
        
        var tempholder: Nibble
        
        //find the position of the decimal in register B
        for i in 0 ..< RegisterLength {
            if registerB.nibbles[i] == point {
                registerB_decimalIndex = i
                break
            }
        }
        //find position of the first non-zero number in register A
        for i in (ExponentLength ... RegisterLength - 2).reverse() {
            if registerA.nibbles[i] > 0 {
                registerAnonzeroIndex = i
                break
            }
            if i == ExponentLength && registerA.nibbles[i] == 0 {
                registerAnonzeroIndex = nil
                noNonzeroNumber = true
            }
        }
        //if there is no non zero number in register A, calculator must be blank
        if registerAnonzeroIndex == nil {
            decimalStringforRegC = "000"
        }
        else { //otherwise, find difference between first nonzero number and decimal to find change in exponent
            adjustDecimal = registerAnonzeroIndex! - registerB_decimalIndex
            if registerA.nibbles[ExponentLength - 1] == minus { //various cases of change in expo
                exponentValue = -1 * exponentValue + adjustDecimal
                if adjustDecimal > 0 {
                    if exponentValue >= 0 && exponentValue < 10 { //depending on the cases
                        decimalStringforRegC = String(empty) + String(empty) + String(exponentValue)
                    } //creates exponent in register C
                    else if exponentValue >= 0 { //more cases for each case...
                        decimalStringforRegC = String(empty) + String(exponentValue)
                    }
                    else {
                        negexponentValue = 100 + exponentValue
                        if negexponentValue < 10 {
                            decimalStringforRegC = String(minus) + String(empty) + String(negexponentValue)
                        }
                        else {
                            decimalStringforRegC = String(minus) + String(negexponentValue)
                        }
                    }
                }
                else {
                    negexponentValue = 100 + exponentValue
                    if negexponentValue < 10 {
                        decimalStringforRegC = String(minus) + String(empty) + String(negexponentValue)
                    }
                    else {
                        decimalStringforRegC = String(minus) + String(negexponentValue)
                    }
                }
            }
            else { //another set of cases for change in expo
                exponentValue += adjustDecimal
                if adjustDecimal > 0 {
                    if exponentValue < 10 {
                        decimalStringforRegC = String(empty) + String(empty) + String(exponentValue)
                    }
                    else {
                        decimalStringforRegC = String(empty) + String(exponentValue)
                    }
                }
                else {
                    if exponentValue >= 0 && exponentValue < 10 {
                        decimalStringforRegC = String(empty) + String(empty) + String(exponentValue)
                    }
                    else if exponentValue >= 0 {
                        decimalStringforRegC = String(empty) + String(exponentValue)
                    }
                    else {
                        negexponentValue = 100 + exponentValue
                        if negexponentValue < 10 {
                            decimalStringforRegC = String(minus) + String(empty) + String(negexponentValue)
                        }
                        else {
                            decimalStringforRegC = String(minus) + String(negexponentValue)
                        }
                    }
                }
            } //need to implement overflow and underflow to the above
        }
        //fills in blank spaces from register B as 0's in register C
        for i in ExponentLength ..< RegisterLength - 1 {
            if registerB.nibbles[i] == blank {
                decimalStringforRegC =  String(empty) + decimalStringforRegC
                if i + 1 != RegisterLength && registerB.nibbles[i + 1] != blank {
                    sigfig = i + 1 //finds where blanks ended in register B
                }
            }
        }
        //picks up from register B and adds digits to register C from register A
        for i in sigfig ..< RegisterLength - 1 {
            decimalStringforRegC = String(registerA.nibbles[i]) + decimalStringforRegC
        }
        //determines sign
        if registerA.nibbles[RegisterLength - 1] == minus {
            decimalStringforRegC = String(minus) + decimalStringforRegC
        }
        else {
            decimalStringforRegC = String(empty) + decimalStringforRegC
        }
        
        registerC = Register(fromDecimalString: decimalStringforRegC)
        //after putting the decimal form of register C into a list, cleans the register
        if noNonzeroNumber == false { //if nonzero exists in A
            while registerC.nibbles[12] < 1 { //moves them up to the first digit position, index 12
                tempholder = registerC.nibbles[12]
                registerC.nibbles.removeAtIndex(12)
                registerC.nibbles.insert(tempholder, atIndex: sigfig)
            }
        }
        
        registers[RegId.C.rawValue] = registerC
    }
    
    // Displays positive or negative overflow value
    func overflow(positive: Bool) {
        registers[RegId.A.rawValue] = Register(fromDecimalString: positive ? "09999999999099" : "99999999999099")
        registers[RegId.B.rawValue] = Register(fromDecimalString: "02000000000000")
        canonicalize()
    }
    
    // Displays underflow value
    func underflow() {
        registers[RegId.A.rawValue] = Register(fromDecimalString: "00000000000000")
        registers[RegId.B.rawValue] = Register(fromDecimalString: "02999999999999")
        canonicalize()
    }
    
    func decimalStringForRegister(regId: RegId) -> String {
        let register = registers[regId.rawValue]
        return register.asDecimalString()
    }
    
}

enum RegId: Int {
    case A = 0 // General Purpose (math or scratchpad)
    case B = 1 // General Purpose (math or scratchpad)
    case C = 2 // X Register
    case D = 3 // Y Register
    case E = 4 // Z Register
    case F = 5 // T (top or trigonemtric) Register
    case M = 6 // Scratchpad (like A and B, but no math)
}
