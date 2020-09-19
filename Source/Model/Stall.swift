//
//  Stalls.swift
//  Barg-InnoFest
//
//  Created by Ryan The on 15/8/20.
//  Copyright © 2020 Ryan The. All rights reserved.
//

import Foundation
import FirebaseFirestore

enum StallModelType: String {
    case select = "select", set = "set"
}

struct StallOwner {
    var uid: String
    var stallName: StallName
}

typealias StallName = String

protocol FoodItem {
    var name: String { get set }
    var desc: String { get set }
    var price: Double { get set }
    var toDictionary: [String: Any] { get }
}

struct FoodItemDetails: FoodItem {
    var name: String
    var desc: String
    var price: Double
    var toDictionary: [String: Any] {
        return [
            "name": self.name,
            "desc": self.desc,
            "price": self.price,
        ]
    }
}

class Stall {
    var name: String
    var desc: String
    var model: StallModelType
    var foodItems: [FoodItem]
    var toDictionary: [String: Any] {
        let foodItems = self.foodItems.map { (foodItem) -> [String: Any] in
            return foodItem.toDictionary
        }
        return [
            "name": self.name,
            "desc": self.desc,
            "model": self.model,
            "foodItems": foodItems,
        ]
    }
    
    init(name: String, desc: String, model: StallModelType, foodItems: [FoodItemDetails]) {
        self.name = name
        self.desc = desc
        self.model = model
        self.foodItems = foodItems
    }
    
    static func fromQuerySnapshot(_ snapshot: QuerySnapshot) -> [Stall] {
        return snapshot.documents.map { (document) -> Stall in
            let documentData = document.data()

            let foodItems = (documentData["foodItems"] as! [[String: Any]]).map { (foodItem) -> FoodItemDetails in
                return FoodItemDetails(name: foodItem["name"] as! String, desc: foodItem["desc"] as! String, price: foodItem["price"] as! Double)
            }
            
            return Stall(name: documentData["name"] as! String, desc: documentData["desc"] as! String, model: StallModelType(rawValue: documentData["model"] as! String) ?? .select, foodItems: foodItems)
        }
    }
    
    static func get(completionHandler: @escaping (_ data: [Stall]) -> ()) {
        let appDelegate = (UIApplication.shared.delegate) as! AppDelegate
        appDelegate.firestoreDb?.collection("stalls").getDocuments(completion: { (querySnapshot, error) in
            if let error = error {
                fatalError("ERROR: %@ \(error)")
            }
            if let querySnapshot = querySnapshot, !querySnapshot.isEmpty {
                completionHandler(Stall.fromQuerySnapshot(querySnapshot))
            }
        })
    }
    
    static func delete(foodItem: FoodItem, from stallName: StallName, completionHandler: @escaping () -> Void) {
        let appDelegate = (UIApplication.shared.delegate) as! AppDelegate
        appDelegate.firestoreDb?.collection("stalls").document(stallName).updateData(["foodItems": FieldValue.arrayRemove([foodItem.toDictionary])]) { error in
            if let error = error {
                fatalError("ERROR: \(error)")
            }
        }
    }
    
    static func add(foodItem: FoodItem, to stallName: StallName, completionHandler: @escaping () -> Void) {
        let appDelegate = (UIApplication.shared.delegate) as! AppDelegate
        appDelegate.firestoreDb?.collection("stalls").document(stallName).updateData(["foodItems": FieldValue.arrayUnion([foodItem.toDictionary])]) { error in
            if let error = error {
                fatalError("ERROR: \(error)")
            }
            completionHandler()
        }
    }
    
    static func toggleFoodItemStar(for foodItem: FoodItem) {
        if (UserDefaults.standard.array(forKey: "favorites") == nil) {
            UserDefaults.standard.set([], forKey: "favorites")
        }
        let favorites = UserDefaults.standard.array(forKey: "favorites")! as! [String]
        var newFavorites = favorites
        if favorites.contains(where: { $0 == foodItem.name }) {
            newFavorites.removeAll { $0 == foodItem.name }
        } else {
            newFavorites.append(foodItem.name)
        }
        UserDefaults.standard.set(newFavorites, forKey: "favorites")
    }
    
    static func isFoodItemStar(for foodItem: FoodItem) -> Bool {
        if (UserDefaults.standard.array(forKey: "favorites") == nil) {
            UserDefaults.standard.set([], forKey: "favorites")
        }
        let favorites = UserDefaults.standard.array(forKey: "favorites")! as! [String]
        return favorites.contains { $0 == foodItem.name }
    }
    
    static func sendTransactionRequest(_ foodItems: [FoodItem], completionHandler: @escaping (_ didSuccess: Bool) -> Void) {
        for foodItem in foodItems {
            print(foodItem.name)
        }
        completionHandler(true)
    }
}
