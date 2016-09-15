//
//  ContactsTableViewController.swift
//  Contact Browser
//
//  Created by Asaph Yuan on 9/13/16.
//  Copyright © 2016 Asaph Yuan. All rights reserved.
//

import UIKit
import Contacts
import ContactsUI

class ContactsTableViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate {
    
    let contactModel = ContactsViewModel()

    var searchController: UISearchController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSearchController()
        setTitle()
        getContacts()
    }
    
    private func configureSearchController()
    {
        // Initialize and perform a minimum configuration to the search controller.
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search here..."
        searchController.searchBar.delegate = self
        searchController.searchBar.sizeToFit()
        
        // Place the search bar view to the tableview headerview.
        self.tableView!.tableHeaderView = searchController.searchBar
    }
    
    internal func updateSearchResults(for searchController: UISearchController) {
        contactModel.filterContentForSearchText(searchText: searchController.searchBar.text!)
        tableView.reloadData()
        
    }
    
    private func setTitle(){
        self.title = "Contacts Browser"
    }
    
    private func getContacts(){
        DispatchQueue.main.async(execute: { () -> Void in
            self.contactModel.contacts = self.contactModel.findContacts()
            DispatchQueue.main.async(execute: { () -> Void in
                self.contactModel.getIndexLetters(contacts: self.contactModel.contacts)
                self.contactModel.sortContacts(contacts: self.contactModel.contacts)
                self.tableView!.reloadData()
            })
        })
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return 1
        }
        return self.contactModel.sortedKeys.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if searchController.isActive && searchController.searchBar.text != "" {
            return ""
        }
        return self.contactModel.sortedKeys[section]
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //if searching and search text is not ""
        if searchController.isActive && searchController.searchBar.text != "" {
            return contactModel.filteredContacts.count
        }
        let sectionTitle = self.contactModel.sortedKeys[section]
        return self.contactModel.sortedDict[sectionTitle]![0].count;
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int)
        -> Int {
            return index
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if searchController.isActive && searchController.searchBar.text != "" {
            return []
        }
        return self.contactModel.sortedKeys
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath)
        let contact: CNContact
        //if searching and search text is not ""
        if searchController.isActive && searchController.searchBar.text != "" {
            contact = contactModel.filteredContacts[indexPath.row]
        } else {
            let sectionTitle = self.contactModel.sortedKeys[indexPath.section]
            let sectionContacts = self.contactModel.sortedDict[sectionTitle]![0]
            contact = sectionContacts[indexPath.row]
        }
        
        cell.textLabel!.text = "\(contact.givenName) \(contact.familyName)"
        //get first number
        let numberArray = contact.phoneNumbers[0].value.stringValue
        
        cell.detailTextLabel!.text = contactModel.formatPhoneNumber(phoneNum: numberArray)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sectionTitle = self.contactModel.sortedKeys[indexPath.section]
        let sectionContacts = self.contactModel.sortedDict[sectionTitle]![0]
        let contact: CNContact

        if searchController.isActive && searchController.searchBar.text != "" {
            contact = contactModel.filteredContacts[indexPath.row]
        } else {
            contact = sectionContacts[indexPath.row]
        }
        //get first number
        let numberArray = contact.phoneNumbers[0].value.stringValue
        
        let alertController = UIAlertController(title: "Call Confirmation", message: "Would you like to call \(contact.givenName) at number: \(contactModel.formatPhoneNumber(phoneNum: numberArray))?", preferredStyle: .alert)
        
        let actionYes = UIAlertAction(title: "Yes", style: .default) { (action:UIAlertAction) in

            if let phoneCallURL = NSURL(string: "telprompt://\(self.contactModel.stripNonNumbers(phoneNum: contact.phoneNumbers[0].value.stringValue))") {
                let application = UIApplication.shared
                if application.canOpenURL(phoneCallURL as URL) {
                    application.open(phoneCallURL as URL)
                }
                else{
                    print("failed")
                }
            }
        }
        
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction) in
        }
        
        alertController.addAction(actionYes)
        alertController.addAction(actionCancel)
        if searchController.isActive && searchController.searchBar.text != "" {
            searchController.present(alertController, animated: true, completion:nil)
        } else {
            self.present(alertController, animated: true, completion:nil)
        }
    }

}
