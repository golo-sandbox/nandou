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
struct futureArgs = { command, message, initialDelay, delay, period, duration  }

augment java.util.concurrent.ExecutorService {
	# callable : closure to execute
	# message : argument passed to callable

	function getFuture = |this, callable, message| {
		let worker = (-> callable(message)):to(java.util.concurrent.Callable.class)
		return this:submit(worker) #future is run when submit()
	}

	function getFuture = |this, args| {
		return this:getFuture(
			  args:command()
			, args:message()
		)
	}

	#http://docs.oracle.com/javase/7/docs/api/java/util/concurrent/ScheduledThreadPoolExecutor.html
	function getScheduledFutureAtFixedRate	= |this, runnable, message, initialDelay, period, duration| {

		let worker = (-> runnable(message)):to(java.lang.Runnable.class)

		let scheduledFuture = this:scheduleAtFixedRate(worker, initialDelay, period, java.util.concurrent.TimeUnit.SECONDS())

		let scheduledWorker = (-> scheduledFuture:cancel(true)):to(java.util.concurrent.Callable.class)

		if duration isnt null {
			this:schedule(scheduledWorker, duration, java.util.concurrent.TimeUnit.SECONDS())
		}

		return scheduledFuture

	}
	#TimUnit : second
	#struct schedFutureArgs = { command, message, initialDelay, period, duration  }
	function getScheduledFutureAtFixedRate = |this, args| {
		return this:getScheduledFutureAtFixedRate(
			  args:command()
			, args:message()
			, args:initialDelay()
			, args:period()
			, args:duration()
		)
	}

	function getScheduleFutureWithFixedDelay	= |this, runnable, message, initialDelay, delay, duration| {

		let worker = (-> runnable(message)):to(java.lang.Runnable.class)

		let scheduledFuture = this:scheduleWithFixedDelay(worker, initialDelay, delay, java.util.concurrent.TimeUnit.SECONDS())

		let scheduledWorker = (-> scheduledFuture:cancel(true)):to(java.util.concurrent.Callable.class)

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
		)
	}


	#run future at ...
	function getScheduledFuture	= |this, callable, message, initialDelay| {
		let worker = (-> callable(message)):to(java.util.concurrent.Callable.class)
		return this:schedule(worker, initialDelay, java.util.concurrent.TimeUnit.SECONDS())
	}
	function getScheduledFuture = |this, args| {
		return this:getScheduledFuture(
			  args:command()
			, args:message()
			, args:initialDelay()
		)
	}

	function waitWhenShutdown = |this, delay| {
		this:awaitTermination(delay, java.util.concurrent.TimeUnit.SECONDS())
	}
}
