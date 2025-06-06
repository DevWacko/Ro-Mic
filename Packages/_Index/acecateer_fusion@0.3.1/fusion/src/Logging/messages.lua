--!strict
--!nolint LocalShadow

--[[
	Stores templates for different kinds of logging messages.
]]

return {
	callbackError = "Error in callback: ERROR_MESSAGE",
	cannotAssignProperty = "The class type '%s' has no assignable property '%s'.",
	cannotConnectChange = "The %s class doesn't have a property called '%s'.",
	cannotConnectEvent = "The %s class doesn't have an event called '%s'.",
	cannotCreateClass = "Can't create a new instance of class '%s'.",
	cleanupWasRenamed = "`Fusion.cleanup` was renamed to `Fusion.doCleanup`. This will be an error in future versions of Fusion.",
	destroyedTwice = "Attempted to destroy %s twice; ensure you're not manually calling `:destroy()` while using scopes. See discussion #292 on GitHub for advice.",
	destructorRedundant = "%s destructors no longer do anything. If you wish to run code on destroy, `table.insert` a function into the `scope` argument. See discussion #292 on GitHub for advice.",
	forKeyCollision = "The key '%s' was returned multiple times simultaneously, which is not allowed in `For` objects.",
	invalidAttributeChangeHandler = "The change handler for the '%s' attribute must be a function.",
	invalidAttributeOutType = "[AttributeOut] properties must be given Value objects.",
	invalidChangeHandler = "The change handler for the '%s' property must be a function.",
	invalidEventHandler = "The handler for the '%s' event must be a function.",
	invalidOutProperty = "The %s class doesn't have a property called '%s'.",
	invalidOutType = "[Out] properties must be given Value objects.",
	invalidPropertyType = "'%s.%s' expected a '%s' type, but got a '%s' type.",
	invalidRefType = "Instance refs must be Value objects.",
	invalidSpringDamping = "The damping ratio for a spring must be >= 0. (damping was %.2f)",
	invalidSpringSpeed = "The speed of a spring must be >= 0. (speed was %.2f)",
	mergeConflict = "Multiple definitions for '%s' found while merging.",
	mistypedSpringDamping = "The damping ratio for a spring must be a number. (got a %s)",
	mistypedSpringSpeed = "The speed of a spring must be a number. (got a %s)",
	mistypedTweenInfo = "The tween info of a tween must be a TweenInfo. (got a %s)",
	noTaskScheduler = "Fusion is not connected to an external task scheduler.",
	possiblyOutlives = "%s could be destroyed before %s; review the order they're created in, and what scopes they belong to. See discussion #292 on GitHub for advice.",
	propertySetError = "Error setting property: ERROR_MESSAGE",
	scopeMissing = "To create %s, provide a scope. (e.g. `%s`). See discussion #292 on GitHub for advice.",
	springTypeMismatch = "The type '%s' doesn't match the spring's type '%s'.",
	stateGetWasRemoved = "`StateObject:get()` has been replaced by `use()` and `peek()` - see discussion #217 on GitHub.",
	unknownMessage = "Unknown error: ERROR_MESSAGE",
	unrecognisedChildType = "'%s' type children aren't accepted by `[Children]`.",
	unrecognisedPropertyKey = "'%s' keys aren't accepted in property tables.",
	unrecognisedPropertyStage = "'%s' isn't a valid stage for a special key to be applied at.",
	useAfterDestroy = "%s is no longer valid - it was destroyed before %s. See discussion #292 on GitHub for advice.",
}