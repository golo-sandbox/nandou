module nandou.Future

import java.util.concurrent.Executors

function getExecutor = -> Executors.newCachedThreadPool()

function getScheduler = -> Executors.newScheduledThreadPool(1)

augment java.util.concurrent.Future {
	# callBackWhenException is a callBack when exception
	function getResult = |this, callBackWhenException| {
		var r  = null
		try {
			r = this:get()
		} catch (e) {
			if callBackWhenException isnt null { callBackWhenException(e) }
		} finally {
			return r
		}
	}

	function getResult = |this| {
		var r  = null
		try {
			r = this:get()
		} finally {
			return r
		}
	}

	function cancelTask = |this, callBackWhenCancelled| {
		this:cancel(true)
		callBackWhenCancelled(this:isCancelled())
	}
}

#TimUnit : second
struct futureArgs = { command, message, initialDelay, delay, period, duration, callback  }

augment java.util.concurrent.ExecutorService {
	# callable : closure to execute
	# message : argument passed to callable
	# callBackWhenSubmitted :
	#  - called when callable is submitted by ExecutorService
	#  - message is passed as parameter of callBackWhenSubmitted
	# callBackWhenDone : passed as 2nd parameter of the callable
	function getFuture = |this, callable, message, callBackWhenDone, callBackWhenSubmitted| {
		let worker = (-> callable(message, callBackWhenDone)):to(java.util.concurrent.Callable.class)
		if callBackWhenSubmitted isnt null { callBackWhenSubmitted(message) }
		return this:submit(worker) #future is run when submit()
	}

	function getFuture = |this, callable, message, callBackWhenDone| {
		let worker = (-> callable(message, callBackWhenDone)):to(java.util.concurrent.Callable.class)
		return this:submit(worker) #future is run when submit()
	}

	function getFuture = |this, callable, message| {
		let worker = (-> callable(message)):to(java.util.concurrent.Callable.class)
		return this:submit(worker) #future is run when submit()
	}

	function getFuture = |this, args| {
		return this:getFuture(
			  args:command()
			, args:message()
			, args:callback()
		)
	}

	#http://docs.oracle.com/javase/7/docs/api/java/util/concurrent/ScheduledThreadPoolExecutor.html
	function getScheduledFutureAtFixedRate	= |this, runnable, message, initialDelay, period, duration, callBackWhenDone| {

		let worker = (-> runnable(message, callBackWhenDone)):to(java.lang.Runnable.class)

		let scheduledFuture = this:scheduleAtFixedRate(worker, initialDelay, period, java.util.concurrent.TimeUnit.SECONDS())

		let scheduledWorker = (-> scheduledFuture:cancel(true)):to(java.util.concurrent.Callable.class)
		#callback???
		if duration isnt null {
			this:schedule(scheduledWorker, duration, java.util.concurrent.TimeUnit.SECONDS())
		}

		return scheduledFuture

	}
	#TimUnit : second
	#struct schedFutureArgs = { command, message, initialDelay, period, duration, callback  }
	function getScheduledFutureAtFixedRate = |this, args| {
		return this:getScheduledFutureAtFixedRate(
			  args:command()
			, args:message()
			, args:initialDelay()
			, args:period()
			, args:duration()
			, args:callback()
		)
	}

	function getScheduleFutureWithFixedDelay	= |this, runnable, message, initialDelay, delay, duration, callBackWhenDone| {

		let worker = (-> runnable(message, callBackWhenDone)):to(java.lang.Runnable.class)

		let scheduledFuture = this:scheduleWithFixedDelay(worker, initialDelay, delay, java.util.concurrent.TimeUnit.SECONDS())

		let scheduledWorker = (-> scheduledFuture:cancel(true)):to(java.util.concurrent.Callable.class)
		#callback???
		if duration isnt null {
			this:schedule(scheduledWorker, duration, java.util.concurrent.TimeUnit.SECONDS())
		}

		return scheduledFuture

	}
	#TimUnit : second
	#struct schedFutureArgs = { command, message, initialDelay, period, duration, callback  }
	function getScheduleFutureWithFixedDelay = |this, args| {
		return this:getScheduledFutureAtFixedRate(
			  args:command()
			, args:message()
			, args:initialDelay()
			, args:delay()
			, args:duration()
			, args:callback()
		)
	}


	#run future at ...
	function getScheduledFuture	= |this, callable, message, initialDelay, callBackWhenDone| {
		let worker = (-> callable(message, callBackWhenDone)):to(java.util.concurrent.Callable.class)
		return this:schedule(worker, initialDelay, java.util.concurrent.TimeUnit.SECONDS())
	}
	function getScheduledFuture = |this, args| {
		return this:getScheduledFuture(
			  args:command()
			, args:message()
			, args:initialDelay()
			, args:callback()
		)
	}

	function waitWhenShutdown = |this, delay| {
		this:awaitTermination(delay, java.util.concurrent.TimeUnit.SECONDS())
	}
}
