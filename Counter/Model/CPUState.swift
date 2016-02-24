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
        
        let registerA = registers[RegId.A.rawValue]
        let registerB = registers[RegId.B.rawValue]
        var registerC: Register
        let minus = RegisterASpecialValues.Minus.rawValue
        let blank = RegisterBSpecialValues.Blank.rawValue
        let point = RegisterBSpecialValues.Point.rawValue
        let empty = RegisterCSpecialValues.Empty.rawValue
        
        var exponent = registerA.nibbles[0] + registerA.nibbles[1] * 10
        var decimalStringforRegC: String
        var sigfig = 0
        
        print(registerA)
        print(registerB)

        if registerA.nibbles[2] == minus {
            exponent = 100 - exponent
            if exponent > 99 {
                exponent = 99
            }
            decimalStringforRegC = String(minus)
            if exponent < 10 {
                decimalStringforRegC = String(minus) + String(empty)
            }
            decimalStringforRegC = decimalStringforRegC + String(exponent)
        }

        else {
            decimalStringforRegC = String(empty)
            if exponent < 10 {
                decimalStringforRegC = String(empty) + String(empty)
            }
            decimalStringforRegC = decimalStringforRegC + String(exponent)
        }
        
        print (decimalStringforRegC)
        
        for i in ExponentLength ..< RegisterLength - 1 {
            if registerB.nibbles[i] == blank {
                decimalStringforRegC =  String(empty) + decimalStringforRegC
                if i + 1 != RegisterLength && registerB.nibbles[i + 1] != blank {
                    sigfig = i + 1
                }
            }
            
        }
        print(sigfig)
        print(decimalStringforRegC) //good for now; stops at the decimal
        
        for i in sigfig ..< RegisterLength - 1 {
            decimalStringforRegC = String(registerA.nibbles[i]) + decimalStringforRegC
        }
        
        if registerA.nibbles[RegisterLength - 1] == minus {
            decimalStringforRegC = String(minus) + decimalStringforRegC
        }
        else {
            decimalStringforRegC = String(empty) + decimalStringforRegC
        }
        
        //decimalStringforRegC = decimalStringforRegC + "00000000000"
        print (decimalStringforRegC)
        
        registerC = Register(fromDecimalString: decimalStringforRegC)
        /* use while loop until decimal is in index 11
        if sigfig == RegisterLength - 1 {
            if registerC.nibbles[2] == minus {
                if registerC.nibbles[0] == 0 {
                    registerC.nibbles[0] == 9
                    registerC.nibbles[1] -= 1 //add if nibbles[1] == 9 then overflow
                }
                else {
                    registerC.nibbles[0] -= 1
                }
            }
            //-1 to exp; if neg already +1
        }
        else if sigfig != RegisterLength - 2 {
            //+ exp until sigfig == registerlength - 2
        }
        */
        
        registers[RegId.C.rawValue] = registerC
        
        print(registerC)
        //let exponentIsNegative = if nibble 2 of register B is 9 then the exponent is negative
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
