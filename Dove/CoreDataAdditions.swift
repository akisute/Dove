//
//  CoreDataAdditions.swift
//  Dove
//
//  Created by Ono Masashi on 2014/08/04.
//  Copyright (c) 2014年 akisute. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    
    private func _save() -> NSError? {
        
        if !self.hasChanges {
            return nil
        }
        
        var error: NSError? = nil
        if (!self.save(&error)) {
            #if DEBUG
                if let e = error {
                NSLog("Failed to save in context: %@", e);
                }
            #endif
            return error
        }
        
        return nil
    }
    
    public func saveWithBlock(block: (NSManagedObjectContext)->()) {
        self.performBlockAndWait({
            block(self)
            if let error = self._save() {
                #if DEBUG
                #endif
            }
        })
    }
    
    public func saveAsynchronouslyWithBlock(block: (NSManagedObjectContext)->()){
        self.performBlock({
            block(self)
            if let error = self._save() {
                #if DEBUG
                #endif
            }
        })
    }
    
}

extension NSManagedObject {

    public class var entityName:String {
        get {
            return NSStringFromClass(self).componentsSeparatedByString(".").last!
        }
    }

    public var objectIDString:String {
        get {
            return self.objectID.URIRepresentation().absoluteString!
        }
    }

    public var isPersisted:Bool {
        get {
            return self.committedValuesForKeys(nil).count > 0
        }
    }

    public func obtainPermanentID() -> Bool {
        if !self.managedObjectContext.obtainPermanentIDsForObjects([self], error: nil) {
            assert(false, "Failed to obtain permanent ID for object.")
            return false
        }
        return true
    }

    public func delete(context: NSManagedObjectContext = CoreDataManager.sharedInstance.mainContext) {
        context.deleteObject(self)
    }

    private class func fetchRequest(predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]?, context: NSManagedObjectContext) -> NSFetchRequest {
        let request = NSFetchRequest()
        request.entity = NSEntityDescription.entityForName(self.entityName, inManagedObjectContext: context)
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        return request
    }

    public class func find(predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = CoreDataManager.sharedInstance.mainContext) -> [NSManagedObject] {
        let request = self.fetchRequest(predicate, sortDescriptors: sortDescriptors, context: context)
        if let objects = context.executeFetchRequest(request, error: nil) {
            return objects as [NSManagedObject]
        } else {
            return []
        }
    }
    
    public class func findAll(sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = CoreDataManager.sharedInstance.mainContext) -> [NSManagedObject] {
        let predicate = NSPredicate(value: true)
        return self.find(predicate, sortDescriptors: sortDescriptors, context: context)
    }
    
    public class func findFirst(predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = CoreDataManager.sharedInstance.mainContext) -> NSManagedObject? {
        let request = self.fetchRequest(predicate, sortDescriptors: sortDescriptors, context: context)
        request.fetchLimit = 1
        if let objects = context.executeFetchRequest(request, error: nil) {
            return objects.first as NSManagedObject?
        } else {
            return nil
        }
    }
    
    public class func get(objectID: NSManagedObjectID, context: NSManagedObjectContext = CoreDataManager.sharedInstance.mainContext) -> NSManagedObject? {
        return context.existingObjectWithID(objectID, error: nil)
    }

    public class func count(predicate: NSPredicate, context: NSManagedObjectContext = CoreDataManager.sharedInstance.mainContext) -> Int {
        let request = self.fetchRequest(predicate, sortDescriptors: nil, context: context)
        let count = context.countForFetchRequest(request, error: nil)
        return count
    }
    
    public class func countAll(context: NSManagedObjectContext = CoreDataManager.sharedInstance.mainContext) -> Int {
        let predicate = NSPredicate(value: true)
        return self.count(predicate, context: context)
    }

    public class func insert(context: NSManagedObjectContext = CoreDataManager.sharedInstance.mainContext) -> NSManagedObject {
        return NSEntityDescription.insertNewObjectForEntityForName(self.entityName, inManagedObjectContext: context) as NSManagedObject
    }

    public class func findFirstOrInsert(predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext = CoreDataManager.sharedInstance.mainContext) -> NSManagedObject {
        let request = self.fetchRequest(predicate, sortDescriptors: sortDescriptors, context: context)
        request.fetchLimit = 1
        if let objects = context.executeFetchRequest(request, error: nil) {
            if let object = objects.first as? NSManagedObject {
                return object
            }
        }
        return self.insert(context: context)
    }

    public class func getOrInsert(objectID: NSManagedObjectID, context: NSManagedObjectContext = CoreDataManager.sharedInstance.mainContext) -> NSManagedObject {
        if let object = context.existingObjectWithID(objectID, error: nil) {
            return object
        } else {
            return self.insert(context: context)
        }
    }

    public class func delete(predicate: NSPredicate, context: NSManagedObjectContext = CoreDataManager.sharedInstance.mainContext) {
        let request = self.fetchRequest(predicate, sortDescriptors: nil, context: context)
        request.includesPropertyValues = false

        if let objects = context.executeFetchRequest(request, error: nil) {
            for object in objects {
                if let managedObject = object as? NSManagedObject {
                    context.deleteObject(managedObject)
                }
            }
        }
    }
}