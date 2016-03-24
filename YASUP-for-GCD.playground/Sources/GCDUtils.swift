//
//  GCDUtils.swift
//  GCDUtils
//
//  Created by Kyle Roucis on 15-7-6.
//  Copyright © 2015 Kyle Roucis. All rights reserved.
//

import Foundation

public func dispatchAsync(qualityOfService qos: qos_class_t = QOS_CLASS_DEFAULT, toBackground background: () -> Void, toMain mainBlockOrNil: (() -> Void)?)
{
    dispatchAsync(qualityOfService: qos) { () -> Void in
        background()
        if let mainBlock = mainBlockOrNil
        {
            dispatchAsyncMain(mainBlock)
        }
    }
}

public func dispatchAsync(qualityOfService qos: qos_class_t = QOS_CLASS_DEFAULT, toBackground background: () -> Void) -> Void
{
    dispatch_async(dispatch_get_global_queue(qos, 0)) { () -> Void in
        background()
    }
}

public func dispatchSync(qualityOfService qos: qos_class_t = QOS_CLASS_DEFAULT, toBackground background: () -> Void) -> Void
{
    dispatch_sync(dispatch_get_global_queue(qos, 0)) { () -> Void in
        background()
    }
}


public func dispatchAsyncMain(main: () -> Void) -> Void
{
    dispatch_async(dispatch_get_main_queue(), main)
}

public func dispatchSyncMain(main: () -> Void) -> Void
{
    dispatch_sync(dispatch_get_main_queue(), main)
}

public func wait(qualityOfService qos: qos_class_t = QOS_CLASS_DEFAULT, on execute: () -> Void, then: () -> Void)
{
    let group = dispatch_group_create()
    let queue = dispatch_get_global_queue(qos, 0)
    dispatch_group_async(group, queue, execute)
    dispatch_group_notify(group, queue, then)
}

public func synchronized<T>(lock: AnyObject, block: () -> T) -> T
{
    objc_sync_enter(lock)
    let retVal: T = block()
    objc_sync_exit(lock)
    return retVal
}

////////////////////////////////////////////////////////////////////////////////////////////////////
//                              === Custom Async Operator Semantics ===
//
//  }- likely indicates a closure that will be moved to a different queue.
//  ~> indicates the dispatch is non-synchronous.
//  !> indicates the dispatch is synchronous.
//  | indicates the main thread is the queue to which the block will be posted.
//  / indicates a default quality-of-service background queue will handle the block.
//
//  EXAMPLES:
//
//  { doSomethingAsyncInBackground() }-~>/
//  { doSynchronousMainThreadWork() }-!>|
//  { workInBackground() } -~>/-~>| { thenWorkInMainQueue() }
//  aBlockInAVarDispatchedToTheBackground-~>/
//
//  NOTE:
//  Occasionally, Swift will try to interpret a stand-alone closure as a trailing closure for a
//  method call. In this case it will complain about too many or incorrect arguments for that
//  method. Simply use a ';' to separate the offending method call from the closure.
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//
// MARK: - Sync Main
//
postfix operator -!>| { }
public postfix func -!>|(main: () -> Void)
{
    dispatchSyncMain(main)
}

//
// MARK - Sync Background
//
postfix operator -!>/ { }
public postfix func -!>/(background: () -> Void)
{
    dispatchSync(toBackground: background)
}

//
// MARK - Async Main
//
postfix operator -~>| { }
public postfix func -~>|(main: () -> Void)
{
    dispatchAsyncMain(main)
}

//
// MARK - Async Background
//
postfix operator -~>/ { }
public postfix func -~>/(background: () -> Void)
{
    dispatchAsync(toBackground: background)
}

//
// MARK - Async Background to Async Main
//
infix operator -~>/-~>| { }
public func -~>/-~>|(background: () -> Void, main: () -> Void)
{
    dispatchAsync(toBackground: background, toMain: main)
}

infix operator !! { }
public func !!(first: () -> Void, second: () -> Void)
{
    wait(on: first, then: second)
}
