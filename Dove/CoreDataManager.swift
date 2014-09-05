//
//  CoreDataManager.swift
//  Dove
//
//  Created by Ono Masashi on 2014/08/04.
//  Copyright (c) 2014年 akisute. All rights reserved.
//

import Foundation
import CoreData

public class CoreDataManager {
    
    public class var sharedInstance: CoreDataManager {
        get {
            struct Static {
                static let instance: CoreDataManager = CoreDataManager()
            }
            return Static.instance
        }
    }
    
    public init() {
    }
    
    // MARK: - Private
    
    private var _modelName: String? = nil
    private var modelName: String {
        get {
            if let name = _modelName {
                return name
            } else {
                let name = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleName") as String
                _modelName = name
                return name
            }
        }
    }
    
    private var persistentStoreURL: NSURL {
        get {
            let pathes = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.LibraryDirectory, NSSearchPathDomainMask.UserDomainMask, true)
            if let path = pathes.first as? String {
                let fullpath = path.stringByAppendingPathComponent(self.modelName + ".sqlite")
                let urlString = "file://\(fullpath)"
                return NSURL.URLWithString(urlString)
            } else {
                // XXX: Won't happen
                return NSURL()
            }
        }
    }
    
    private var _model: NSManagedObjectModel? = nil
    private var model: NSManagedObjectModel {
        get {
            if let m = _model {
                return m
            } else {
                let bundles = [NSBundle.mainBundle()]
                let m = NSManagedObjectModel.mergedModelFromBundles(bundles)
                _model = m
                return m
            }
        }
    }
    
    private var _persistentStoreCoordinator: NSPersistentStoreCoordinator? = nil
    private var persistentStoreCoordinator: NSPersistentStoreCoordinator {
        get {
            if let coordinator = _persistentStoreCoordinator {
                return coordinator
            } else {
                let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.model)
                var error: NSError? = nil
                coordinator.addPersistentStoreWithType(
                    NSSQLiteStoreType,
                    configuration: nil,
                    URL: self.persistentStoreURL,
                    options: [NSMigratePersistentStoresAutomaticallyOption:true, NSInferMappingModelAutomaticallyOption:true],
                    error: &error)
                if let e = error {
                    NSLog("Failed to add persistent store: %@", e)
                }
                _persistentStoreCoordinator = coordinator
                return coordinator
            }
        }
    }
    
    // MARK: - Application-Wide Contexts
    
    private var _mainContext:NSManagedObjectContext? = nil
    public var mainContext:NSManagedObjectContext {
        get {
            if let context = _mainContext {
                return context
            } else {
                let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
                context.parentContext = self.rootContext
                _mainContext = context
                return context
            }
        }
    }
    private var _backgroundContext:NSManagedObjectContext? = nil
    public var backgroundContext:NSManagedObjectContext {
        get {
            if let context = _backgroundContext {
                return context
            } else {
                let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
                context.parentContext = self.mainContext
                _backgroundContext = context
                return context
            }
        }
    }
    private var _rootContext:NSManagedObjectContext? = nil
    public var rootContext:NSManagedObjectContext {
        get {
            if let context = _rootContext {
                return context
            } else {
                let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
                context.persistentStoreCoordinator = self.persistentStoreCoordinator
                _rootContext = context
                return context
            }
        }
    }
    
    // MARK: - Managing Persistent Stores
    
    public func deletePersistentStore() {
        let fileManager = NSFileManager()
        fileManager.removeItemAtURL(self.persistentStoreURL, error: nil)
    }
}
