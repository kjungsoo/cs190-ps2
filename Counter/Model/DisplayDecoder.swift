//
//  DisplayDecoder.swift
//  Calculator
//
//  Created by Brian Hill github.com/brianhill on 2/12/16.
//

// As noted in README.md this web page has a very nice HP-35 emulator:
//
// http://home.citycable.ch/pierrefleur/HP-Classic/HP-Classic.html
//
// Of course it is one thing to see it and another thing to decipher the implementation choices.
//
// We are told by Jacques Laporte how the A and B registers determine what is displayed:
//
// http://home.citycable.ch/pierrefleur/Jacques-Laporte/Output%20format.htm
// 
// Be careful, there my be errors in his examples. Use the HP-35 emulator link above to get better examples.
//
// The A register is set up to hold the display in floating point format and its digits
// are in proper order while the B register is used as a masking register with digit “9”
// for each digit position to be blanked, digit”2” for the decimal point position and
// digit “0” for displayed digit position.
//
// Laporte also has a page devoted specifically to floating point representation,
//
// http://home.citycable.ch/pierrefleur/Jacques-Laporte/Floating%20point.htm
//
// and the page has an example with both a negative mantissa and a negative exponent.

// This is a 15-digit display.
let numberOfSSCs = 15

enum DisplayableCharacters: Character {
    case Char0 = "0"
    case Char1 = "1"
    case Char2 = "2"
    case Char3 = "3"
    case Char4 = "4"
    case Char5 = "5"
    case Char6 = "6"
    case Char7 = "7"
    case Char8 = "8"
    case Char9 = "9"
    case Point = "."
    case Minus = "-"
    case Blank = " "
}

enum RegisterASpecialValues: Nibble {
    case Minus = 0b1001 // In two places in Register A, 9 in BCD has the interpretation of Minus.
}

enum RegisterBSpecialValues: Nibble {
    case Point = 0b0010 // In Register B, 2 in BCD has the interpretation of Point.
    case Blank = 0b1001 // In Register B, 9 in BCD has the interpretation of Blank.
}

enum RegisterCSpecialValues: Nibble{
    case Empty = 0b000 // In my implementation I intend to use this a lot
}

// An array of the displayable characters is super-handy for converting integers to the corresponding characters.
let displayableCharacters: [DisplayableCharacters] = [
    DisplayableCharacters.Char0,
    DisplayableCharacters.Char1,
    DisplayableCharacters.Char2,
    DisplayableCharacters.Char3,
    DisplayableCharacters.Char4,
    DisplayableCharacters.Char5,
    DisplayableCharacters.Char6,
    DisplayableCharacters.Char7,
    DisplayableCharacters.Char8,
    DisplayableCharacters.Char9
]

class DisplayDecoder {
    
    static let sharedInstance = DisplayDecoder()
    
    // This function consults registers A and B returns an array of
    // 15 displayable characters following the rules elucidated by Laporte.
    func getDisplayableCharacters(registerA: Register, registerB: Register) -> [DisplayableCharacters] {
        
        // Initialize the characters to blanks.
        var characters = [DisplayableCharacters](count:numberOfSSCs, repeatedValue:DisplayableCharacters.Blank)
        
        // The following three variables
        // will be incremented and decremented more or less in step.
        var idxA = RegisterLength - 1
        var idxB = RegisterLength - 1
        var idxCharacters = 0
        
        if registerA.nibbles[idxA] == RegisterASpecialValues.Minus.rawValue {
            // The leading digit of the mantissa is a 9 means display a minus sign in front of the mantissa.
            characters[idxCharacters] = DisplayableCharacters.Minus
        }
        // Increment/decrement
        idxA -= 1
        idxCharacters += 1
        
        while idxA >= ExponentLength {
            var nibbleB = registerB.nibbles[idxB]
            // Consume the decimal point if present and move along.
            if nibbleB == RegisterBSpecialValues.Point.rawValue {
                characters[idxCharacters] = DisplayableCharacters.Point
                // Increment/decrement
                idxCharacters += 1
                idxB -= 1
                nibbleB = registerB.nibbles[idxB]
            }
            // Only if we are not blanked do we need to show what is in A
            if nibbleB != RegisterBSpecialValues.Blank.rawValue {
                let nibble = registerA.nibbles[idxA]
                characters[idxCharacters] = displayableCharacters[Int(nibble)]
            }
            // Increment/decrement
            idxCharacters += 1
            idxA -= 1
            idxB -= 1
        }
        
        let exponentIsNegative = registerA.nibbles[idxA] == RegisterASpecialValues.Minus.rawValue
        if exponentIsNegative {
            characters[idxCharacters] = DisplayableCharacters.Minus
        }
        // Increment/decrement
        idxCharacters += 1
        idxA -= 1
        idxB -= 1
        
        // The exponent in C is in 10's complement if it is negative.
        // However, the exponent in A is already as the user enters and views it.
        while idxA >= 0 {
            let nibbleB = registerB.nibbles[idxB]
            // Only if we are not blanked do we need to show what is in the exponent
            if nibbleB != RegisterBSpecialValues.Blank.rawValue {
                let nibble = registerA.nibbles[idxA]
                characters[idxCharacters] = displayableCharacters[Int(nibble)]
            }
            // Increment/decrement
            idxCharacters += 1
            idxA -= 1
            idxB -= 1
        }
        
        return characters
    }
}

