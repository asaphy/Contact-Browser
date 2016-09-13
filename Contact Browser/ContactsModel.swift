//
//  ContactsModel.swift
//  Contact Browser
//
//  Created by Asaph Yuan on 9/13/16.
//  Copyright © 2016 Asaph Yuan. All rights reserved.
//

import Foundation
import Contacts
import ContactsUI


class Contacts {
    var contacts = [CNContact]()
    var filteredContacts = [CNContact]()

    //returns all contacts in CNContact array
    func findContacts() -> [CNContact] {
        print("findingcontacts")
        //init store
        let store = CNContactStore()
        //keys to fetch
        let keysToFetch = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                           CNContactPhoneNumbersKey] as [Any]
        let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch as! [CNKeyDescriptor])
        var contacts = [CNContact]()
        
        do {
            try store.enumerateContacts(with: fetchRequest, usingBlock: { ( contact, stop) -> Void in
                contacts.append(contact)
            })
        }
        catch let error as NSError {
            print(error.localizedDescription)
        }
        
        return contacts
    }
    
    //filters contacts
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteredContacts = contacts.filter { contact in
            return (contact.givenName.lowercased().hasPrefix(searchText.lowercased()))
        }
    }
}
