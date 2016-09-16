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
    
    var contactModel = ContactsViewModel()

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
        tableView.tableHeaderView = searchController.searchBar
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        contactModel.filterContentForSearchText(searchText: searchController.searchBar.text!)
        tableView.reloadData()
        
    }
    
    private func setTitle(){
        title = "Contacts Browser"
    }
    
    private func getContacts(){
        contactModel.contacts = contactModel.findContacts()
        contactModel.getIndexLetters(contacts: contactModel.contacts)
        contactModel.sortContacts(contacts: contactModel.contacts)
        DispatchQueue.main.async(execute: {
            self.tableView.reloadData()
        })
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return contactModel.getNumberOfSections(searchControllerIsActive: searchController.isActive, searchText: searchController.searchBar.text!)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return contactModel.getTitleForHeaderInSection(searchControllerIsActive: searchController.isActive, searchText: searchController.searchBar.text!, section: section)
    }
    
    
    //TODO: Refactor tableView functions to ContactsViewModel
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contactModel.getNumRows(searchControllerIsActive: searchController.isActive, searchText: searchController.searchBar.text!, section: section)
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int)
        -> Int {
            return index
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return contactModel.getSectionIndexTitles(searchControllerIsActive: searchController.isActive, searchText: searchController.searchBar.text!)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath)
        let contact: CNContact
        //if searching and search text is not ""
        if searchController.isActive && searchController.searchBar.text != "" {
            contact = contactModel.filteredContacts[indexPath.row]
        } else {
            let sectionTitle = contactModel.sortedKeys[indexPath.section]
            guard let sectionContacts = contactModel.sortedDict[sectionTitle]?.first else {return cell}
            contact = sectionContacts[indexPath.row]
        }
        
        cell.textLabel!.text = "\(contact.givenName) \(contact.familyName)"
        //get first number
        guard let numberArray = contact.phoneNumbers.first?.value.stringValue else {return cell}
        
        cell.detailTextLabel!.text = contactModel.formatPhoneNumber(phoneNum: numberArray)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let callAlert = makeCallAlert(indexPath: indexPath)
        
        if searchController.isActive && searchController.searchBar.text != "" {
            searchController.present(callAlert, animated: true, completion:nil)
        } else {
            present(callAlert, animated: true, completion:nil)
        }
    }
    
    func makeCallAlert (indexPath: IndexPath) -> UIAlertController {
        let sectionTitle = contactModel.sortedKeys[indexPath.section]

        guard let sectionContacts = contactModel.sortedDict[sectionTitle]?.first else{return UIAlertController()}

        let contact: CNContact
        
        if searchController.isActive && searchController.searchBar.text != "" {
            contact = contactModel.filteredContacts[indexPath.row]
        } else {
            contact = sectionContacts[indexPath.row]
        }
        guard let numberString = contact.phoneNumbers.first?.value.stringValue else {return UIAlertController()}
        let alertController = UIAlertController(title: "Call Confirmation", message: "Would you like to call \(contact.givenName) at number: \(contactModel.formatPhoneNumber(phoneNum: numberString))?", preferredStyle: .alert)
    
        let actionYes = UIAlertAction(title: "Yes", style: .default) { (action:UIAlertAction) in
            if let phoneCallURL = NSURL(string: "telprompt://\(self.contactModel.stripNonNumbers(phoneNum: contact.phoneNumbers[0].value.stringValue))") {
                let application = UIApplication.shared
                if application.canOpenURL(phoneCallURL as URL) {
                    application.open(phoneCallURL as URL)
                } else{
                    print("phone call failed")
                }
            }
        }
    
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction) in
        }
    
        alertController.addAction(actionYes)
        alertController.addAction(actionCancel)
        return alertController
    }

}
