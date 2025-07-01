//
//  ExpenseEntity.swift
//  Kostentracker
//
//  Created by Moritz Gebhardt on 30.06.25.
//


import Foundation
import CoreData

@objc(ExpenseEntity)
public class ExpenseEntity: NSManagedObject {
}

extension ExpenseEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExpenseEntity> {
        return NSFetchRequest<ExpenseEntity>(entityName: "ExpenseEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var amount: Double
    @NSManaged public var frequencyUnitRaw: String
    @NSManaged public var frequencyValue: Int32
    @NSManaged public var date: Date
    @NSManaged public var categoryRaw: String
    @NSManaged public var notes: String
}

extension ExpenseEntity: Identifiable {
    public var wrappedId: UUID {
        id
    }
    
    public var wrappedTitle: String {
        title
    }
    
    public var wrappedDate: Date {
        date
    }
    
    public var wrappedNotes: String {
        notes
    }
    
    var frequencyUnit: FrequencyUnit {
        get { FrequencyUnit(rawValue: frequencyUnitRaw) ?? .months }
        set { frequencyUnitRaw = newValue.rawValue }
    }

    var category: Category {
        get { Category(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
}

extension ExpenseEntity {
    static func createDefault(in context: NSManagedObjectContext) -> ExpenseEntity {
        let entity = ExpenseEntity(context: context)
        entity.id = UUID()
        entity.title = "Unnamed"
        entity.amount = 0.0
        entity.frequencyUnit = FrequencyUnit.months
        entity.frequencyValue = 1
        entity.date = Date()
        entity.category = Category.other
        entity.notes = ""
        return entity
    }
}


