//
//  ContactsManage.swift
//  AddressBook
//
//  Created by Q Z on 2023/6/13.
// https://developer.aliyun.com/article/932460

import UIKit
import Contacts

class ContactsManage: NSObject {
    private let keys = [CNContactFamilyNameKey as CNKeyDescriptor,
                        CNContactOrganizationNameKey as CNKeyDescriptor,
                        CNContactGivenNameKey as CNKeyDescriptor,
                        CNContactPhoneNumbersKey as CNKeyDescriptor]
    private let contactStore: CNContactStore = CNContactStore()
    private var callback: (([[String: String]])-> ())?
    
    public var contactAuthorizationStatus: CNAuthorizationStatus {
        return CNContactStore.authorizationStatus(for: .contacts)
    }
    
    static let `default`: ContactsManage = {
        return ContactsManage()
    }()
    
    public func register(callback: @escaping (([[String: String]]) -> ())){
        self.callback = callback
        //如果没有授权则退出
        contactStore.requestAccess(for: .contacts, completionHandler: { (granted, error) in
            if granted && error == nil {
                self.loadContacts()
            }
        })
    }
    
    private func loadContacts() {
        DispatchQueue.global(qos: .background).async {
            let request = CNContactFetchRequest(keysToFetch: self.keys)
            var contacts = [[String: String]]()
            do {
                try self.contactStore.enumerateContacts(with: request) { contact, pointer in
                    var name = contact.givenName
                    if !String.isEmpty(contact.familyName) {
                        name = contact.familyName
                    }
                    
                    if !String.isEmpty(contact.organizationName) {
                        name = contact.organizationName
                    }
                    
                    if String.isEmpty(name){
                        name = contact.phoneNumbers.first?.label ?? ""
                    }
                    if name == "_$!<Mobile>!$_" {
                        name = ""
                    }
                    contacts.append(["name": name,
                                     "phone": contact.phoneNumbers.first?.value.stringValue ?? ""])
                }
            } catch {
                log.info("ContactsManage：\(error)")
            }
            self.callback?(contacts)
        }
    }
    
    func addContact(contact: CNMutableContact){
        let request = CNSaveRequest()
//        let contact = CNMutableContact()
//        contact.givenName = given   // "名"
//        contact.familyName = family // "姓"
//        contact.phoneticGivenName = "なまえ"
//        contact.phoneticFamilyName = "みょうじ"
//        contact.phoneNumbers = [CNLabeledValue<CNPhoneNumber>(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: "000-1234-5678"))]
//        contact.emailAddresses = [CNLabeledValue<NSString>(label: CNLabelHome, value: NSString(string: "ame@sample.com"))]
        request.add(contact, toContainerWithIdentifier: contactStore.defaultContainerIdentifier())
        do {
            try contactStore.execute(request)
        } catch {
            log.info("ContactsManage：\(error)")
        }
    }
}
