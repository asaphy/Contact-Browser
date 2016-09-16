//
//  ContactsViewModel.swift
//  Contact Browser
//
//  Created by Asaph Yuan on 9/13/16.
//  Copyright © 2016 Asaph Yuan. All rights reserved.
//

import Foundation
import Contacts
import ContactsUI

struct ContactsViewModel {
    var contacts = [CNContact]()
    var filteredContacts = [CNContact]()
    var sortedDict: [String:[[CNContact]]] = [:]
    var sortedKeys: [String] = []
    var contactDict: [String:[CNContact]] = [:]
    var filterActive: Bool = false
    
    //returns all contacts in CNContact array
    func findContacts() -> [CNContact] {
        //init store
        let store = CNContactStore()
        //keys to fetch
        let keysToFetch = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                           CNContactPhoneNumbersKey] as [Any]
        // FIXME: dont force cast
        let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch as! [CNKeyDescriptor])
        var contacts = [CNContact]()
        
        do {
            try store.enumerateContacts(with: fetchRequest) { ( contact, stop) -> Void in
                // Checking if phone number exists
                if (contact.phoneNumbers != []) {
                    contacts.append(contact)
                }
            }
        }
        catch let error as NSError {
            print(error.localizedDescription)
        }
        return contacts
    }
    
    //returns all contacts in CNContact array
    mutating func getIndexLetters(contacts: [CNContact]){
        
        for contact in contacts{
            if contact.givenName != "" {
                let firstLetter = String(contact.givenName[contact.givenName.startIndex])
                if contactDict[firstLetter] == nil{
                    contactDict[firstLetter] = [contact]
                }
                else{
                    contactDict[firstLetter]!.append(contact)
                }
            }

        }
        
        sortKeys(keysArray: contactDict.keys)
    }
    
    //filters contacts
    mutating func filterContentForSearchText(searchText: String, scope: String = "All") {
        contacts = contacts.sorted(by: {
            if $0.givenName != $1.givenName {
                return $0.givenName < $1.givenName
            }
            else {
                //last names are the same, break ties by first name
                return $0.familyName < $1.familyName
            }
        })
        filteredContacts = contacts.filter { contact in
            var numberArray = [String]()
            for number in contact.phoneNumbers {
                let phoneNumber = number.value
                numberArray.append(phoneNumber.stringValue)
            }
            let numberString = numberArray.joined(separator: ",")
            return contact.givenName.lowercased().hasPrefix(searchText.lowercased()) || numberString.hasPrefix(searchText)
        }
    }
    
    func formatPhoneNumber (phoneNum: String) -> String{
        var num = phoneNum
        if num.characters.count == 10 {
            num.insert("(", at: num.startIndex)
            num.insert(contentsOf: ") ".characters, at: num.characters.index(num.startIndex, offsetBy: 4))
            num.insert(contentsOf: "-".characters, at: num.characters.index(num.startIndex, offsetBy: 9))
        }
        return num
    }
    
    func stripNonNumbers(phoneNum: String) -> String{
        //pattern says except digits and dot.
        let pattern = "[^0-9]"
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            
            //replace all not required characters with empty string ""
            return regex.stringByReplacingMatches(in: phoneNum, options: NSRegularExpression.MatchingOptions.withTransparentBounds, range: NSMakeRange(0, phoneNum.characters.count), withTemplate: "")
        } catch {
            print("Cant convert")
        }
        return phoneNum
    }
    
    mutating func sortContacts(contacts: [CNContact]){
        var sortedContacts = contacts
        sortedContacts = contacts.sorted(by: {
            if $0.givenName != $1.givenName {
                return $0.givenName < $1.givenName
            }
            else {
                //last names are the same, break ties by first name
                return $0.familyName < $1.familyName
            }
        })
        sortedContactsToDict(contacts: sortedContacts)
    }
    
    mutating func sortedContactsToDict(contacts: [CNContact]){
        for contact in contacts{
            if contact.givenName != "" {
                let firstLetter = String(contact.givenName[contact.givenName.startIndex])
                if sortedDict[firstLetter] == nil{
                    sortedDict[firstLetter] = [[contact]]
                }
                else{
                    sortedDict[firstLetter]![0].append(contact)
                }
            }
        }
    }
    
    mutating func sortKeys(keysArray: LazyMapCollection<Dictionary<String, [CNContact]>, String>){
        sortedKeys = Array(keysArray).sorted()
    }
    
    func getNumberOfSections(searchControllerIsActive: Bool, searchText: String) -> Int {
        if searchControllerIsActive && searchText != "" {
            return 1
        }
        return sortedKeys.count
    }
    
    func getTitleForHeaderInSection(searchControllerIsActive: Bool, searchText: String, section: Int) -> String? {
        if searchControllerIsActive && searchText != "" {
            return ""
        }
        return sortedKeys[section]
    }
    
    func getNumRows (searchControllerIsActive: Bool, searchText: String, section: Int) -> Int {
        //if searching and search text is not ""
        if searchControllerIsActive && searchText != "" {
            return filteredContacts.count
        }
        let sectionTitle = sortedKeys[section]
        if let numRows = sortedDict[sectionTitle]?.first?.count {
            return numRows
        } else {
            return 0
        }
    }
    
    func getSectionIndexTitles (searchControllerIsActive: Bool, searchText: String) -> [String]? {
        if searchControllerIsActive && searchText != "" {
            return []
        }
        return sortedKeys
    }

}
