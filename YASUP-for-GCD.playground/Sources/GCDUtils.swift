//  YASUP for GCD v 1.1.0
//  Copyright © Kyle Roucis 2015-2016

import Foundation

func synchronized<T>(_ lock: AnyObject, block: () -> T) -> T
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
postfix operator -!>|
postfix func -!>|(main: () -> Void)
{
    DispatchQueue.main.sync(execute: main)
}

//
// MARK - Sync Background
//
postfix operator -!>/
postfix func -!>/(background: () -> Void)
{
    DispatchQueue.global().sync(execute: background)
}

//
// MARK - Async Main
//
postfix operator -~>|
postfix func -~>|(main: @escaping () -> Void)
{
    DispatchQueue.main.async(execute: main)
}

//
// MARK - Async Background
//
postfix operator -~>/
postfix func -~>/(background: @escaping () -> Void)
{
    DispatchQueue.global().async(execute: background)
}

//
// MARK - Async Background to Async Main
//
infix operator -~>/-~>|
func -~>/-~>|(background: @escaping () -> Void, main: @escaping () -> Void)
{
    {
        background()
        main-~>|
        }-~>/
}

infix operator !!
func !!(first: @escaping () -> Void, second: @escaping () -> Void)
{
    let group = DispatchGroup()
    let queue = DispatchQueue.global()
    queue.async(group: group, execute: first)
    group.notify(queue: queue, execute: second)
}
