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
    var contactDict: [String:[CNContact]] = [:]
    var sortedKeys: [String] = []
    var searchController: UISearchController!

    private func configureSearchController() {
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
                self.contactDict = self.contactModel.getIndexLetters(contacts: self.contactModel.contacts)
                self.sortedKeys = Array(self.contactDict.keys).sorted()
                self.tableView!.reloadData()
            })
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSearchController()
        setTitle()
        getContacts()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return 1
        }
        return sortedKeys.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if searchController.isActive && searchController.searchBar.text != "" {
            return ""
        }
        return sortedKeys[section]
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //if searching and search text is not ""
        if searchController.isActive && searchController.searchBar.text != "" {
            return contactModel.filteredContacts.count
        }
        let sectionTitle = sortedKeys[section]
        return contactDict[sectionTitle]!.count;
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int)
        -> Int {
            return index
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if searchController.isActive && searchController.searchBar.text != "" {
            return []
        }
        return sortedKeys
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath)
        let contact: CNContact
        //if searching and search text is not ""
        if searchController.isActive && searchController.searchBar.text != "" {
            contact = contactModel.filteredContacts[indexPath.row]
        } else {
            let sectionTitle = sortedKeys[indexPath.section]
            let sectionContacts = contactDict[sectionTitle]!
            contact = sectionContacts[indexPath.row]
        }
        
        cell.textLabel!.text = "\(contact.givenName) \(contact.familyName)"
        cell.detailTextLabel!.text = "\(contact.phoneNumbers)"
        var numberArray = [String]()
        for number in contact.phoneNumbers {
            let phoneNumber = number.value
            numberArray.append(phoneNumber.stringValue)
        }
        
        cell.detailTextLabel!.text = numberArray.joined(separator: ",")
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let contact = contactModel.contacts[indexPath.row]
        var numberArray = [String]()
        print("row selected")
        for number in contact.phoneNumbers {
            let phoneNumber = number.value
            numberArray.append(phoneNumber.stringValue)
        }
        let alertController = UIAlertController(title: "Call Confirmation", message: "Would you like to call \(contact.givenName) at number: \(numberArray.joined(separator: ","))?", preferredStyle: .alert)
        
        let actionYes = UIAlertAction(title: "Yes", style: .default) { (action:UIAlertAction) in
            if let phoneCallURL = NSURL(string: "telprompt://\(contact.phoneNumbers)") {
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
