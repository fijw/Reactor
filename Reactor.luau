--[[
    @header
    ```
        ▀▀▀    ▀▀▀    ▀▀▀    ▀▀▀    ▀▀▀    ▀▀▀    ▀▀▀    ▀▀▀    ▀▀▀    ▀▀▀  
                                                                            
                                                                            
                                                                            
                                                                            
        █           ▄    ▄          ▀                                  █   
        █           █  ▄▀   ▄▄▄   ▄▄▄     ▄ ▄▄   ▄▄▄    ▄▄▄            █   
        █           █▄█    ▀   █    █     █▀  ▀ █▀ ▀█  █   ▀           █   
        █           █  █▄  ▄▀▀▀█    █     █     █   █   ▀▀▀▄           █   
        █           █   ▀▄ ▀▄▄▀█  ▄▄█▄▄   █     ▀█▄█▀  ▀▄▄▄▀           █   
        █                                                              █   
                                                                            
                                                                            
                                                                            
                                                                            
                                                                            
        ▀▀▀    ▀▀▀    ▀▀▀    ▀▀▀    ▀▀▀    ▀▀▀    ▀▀▀    ▀▀▀    ▀▀▀    ▀▀▀  

        @author Kairos (Roblox: @roblox_user_5618502527)
        @version 1.0.1
    ```

    @description Reactor is a state engine library for Roblox.

    @note Anything and everything (including instances) can
    @note be used & have extra functionality added to
    @note it.

    @note Can range from making the inputted state object
    @note callable, subscribing to the object, locking the
    @note object, and adding extra functionality to it, such
    @note as addition, subtraction, division, and more,
    @note methods.

    @note By default, the callback functionality for a
    @note inputted object is to change the inputted
    @note object's data.
    @note This can be used to do things like: add, change, or
    @note completely remove values in the inputted object.
    @note This usually applies to Arrays and Dictionaries.

    @usage
    ```luau
        local StateEngineTest = Reactor({ bob = 41 });
        
        -- Test multiple state changes.
        (
            StateEngineTest(51, "bob") :: AbstractedStateEngine<any>
        )(
            123,
            "test name 1",
            "creature directories",
            "humans directory"
        )(
            456,
            "test name 2",
            "creature directories",
            "humans directory"
        )(
            789,
            "cat",
            "creature directories",
            "pets directory"
        )(
            1_011,
            "dog",
            "creature directories",
            "pets directory"
        )

        -- Test signals.
        do
            StateEngineTest:subscribe(
                function(self, data, key, ...)
                    print(data, key, ..., "subscription callback")
                end
            )
            :wrapToPeek(
                function(self, data)
                    print(self, data, "peek callback")
                end
            );

            (StateEngineTest(100_000, "bobs_bank_balance", "bank_state", "bank_balances") :: AbstractedStateEngine<any>)()

            StateEngineTest:unsubscribe():unwrapToPeek();

            (StateEngineTest(123_456) :: AbstractedStateEngine<any>)()

            StateEngineTest:subscribe(
                function(self, data, key, ...)
                    print(data, key, ..., "subscription callback (once)")
                end,

                true
            )
            :wrapToPeek(
                function(self, data)
                    print(self, data, "peek callback (once)")
                end,

                true
            );

            (StateEngineTest(7_891_011) :: AbstractedStateEngine<any>)()(121_314)()
        end

        -- Test locking.
        do
            StateEngineTest:lock()
            StateEngineTest("should be number type 121_314 still since it's locked, not this")

            StateEngineTest = StateEngineTest:returnUnlocked()
            StateEngineTest("should be this now since it's unlocked")
        end

        -- Test adding methods.
        do
            StateEngineTest
            += {
                methodName = "__div",

                methodCallback
                = function<X>(self: AbstractedStateEngine<any>, data: X): AbstractedStateEngine<any>
                    print(data, "__div callback")

                    return self
                end
            }

            StateEngineTest /= 5
        end

        -- Printing the state engine.
        do
            print(StateEngineTest:getStateDetails(), "State Details")
            print(StateEngineTest, "State Engine")
            print(StateEngineTest(), "State Engine Source")
            print(getmetatable(StateEngineTest), "State Engine Metatable")
        end
    ```
]]
--!strict
--!optimize 2


--[[ @section Types ]]
--[[
    @generic A Abstracted type.
    @generic S Source type.
]]
type AbstractedType<A> = A
export type AbstractedStateEngine<S> = AbstractedType<AbstractedType<AbstractedType<StateEngine<S>>>>


--[[
    @generic_pack P... Path types.

    @generic M Self type.
    @generic S Source type.
    @generic D Data type.
    @generic K Key type.
]]
type SubscriptionCallbackType<M, S> = <D, K, P...>(self: M, data: D | S, key: K?, P...) -> ()

--[[
    @generic M Self type.
    @generic S Source type.
]]
type WrappedPeekCallbackType<M, S> = (self: M, data: S) -> ()

--[[
    @generic M Self type.
    @generic X Method data type.
]]
type MethodCallbackType<M> = <X>(self: M, data: X) -> (M)


type StateDetailsSchema
= {
    isSubscribed: boolean,
    isLocked: boolean,
    isPeekWrapped: boolean
}

--[[ @generic M Self type. ]]
type MethodDetailsSchema<M>
= {
    methodName: string,
    methodCallback: MethodCallbackType<M>
}


--[[
    @generic_pack P... Path types.

    @generic S Source type.
    @generic D Data type.
    @generic K Fresh key type.
    @generic X Method data type.
]]
type StateEngine<S> = setmetatable
<
    {
        source: S,

        subscriptionCallback: SubscriptionCallbackType<StateEngine<S>, S>?,
        subscriptionOnce: true?,

        peekCallback: WrappedPeekCallbackType<StateEngine<S>, S>?,
        peekObserveOnce: true?,
    },

    {
        __index
        : {
            subscribe: (self: StateEngine<S>, callback: SubscriptionCallbackType<StateEngine<S>, S>, once: true?) -> (StateEngine<S>),
            unsubscribe: (self: StateEngine<S>) -> (StateEngine<S>),

            lock: (self: StateEngine<S>) -> (StateEngine<S>),
            returnUnlocked: (self: StateEngine<S>) -> (StateEngine<S>),

            wrapToPeek: (self: StateEngine<S>, callback: (self: StateEngine<S>, data: S) -> (), once: true?) -> (StateEngine<S>),
            unwrapToPeek: (self: StateEngine<S>) -> (StateEngine<S>),

            getStateDetails: (self: StateEngine<S>) -> (StateDetailsSchema)
        },

        __call: <D, K, P...>(self: StateEngine<S>, freshData: D?, freshKey: K?, P...) -> ((S | D) | StateEngine<S>),
        __add: (self: StateEngine<S>, MethodDetails: MethodDetailsSchema<StateEngine<S>>) -> (StateEngine<S>),

        -- Available operators to override.
        __div: MethodCallbackType<StateEngine<S>>,
        __idiv: MethodCallbackType<StateEngine<S>>,
        __sub: MethodCallbackType<StateEngine<S>>,
        __mul: MethodCallbackType<StateEngine<S>>,
        __mod: MethodCallbackType<StateEngine<S>>,
        __pow: MethodCallbackType<StateEngine<S>>,
        __eq: MethodCallbackType<StateEngine<S>>
    }
>
--[[ @end_section Types ]]


local Reactor = {}


--[[ @section Subscription Methods ]]
--[[
    @usage Subscribes a callback to the class.

    @param self AbstractedStateEngine<any>
    @param callback SubscriptionCallbackType<AbstractedStateEngine<any>, any>
    @param once true?

    @return AbstractedStateEngine<any>
]]
local function subscribeCallback
<D>(
    self: AbstractedStateEngine<any>,
    callback: SubscriptionCallbackType<AbstractedStateEngine<any>, any>,
    once: true?
): AbstractedStateEngine<any>
    self.subscriptionCallback = callback
    self.subscriptionOnce = once

    return self
end

--[[
    @usage Unsubscribes a callback from the class.

    @param self AbstractedStateEngine<any>

    @return AbstractedStateEngine<any>
]]
local function unsubscribeCallback(self: AbstractedStateEngine<any>): AbstractedStateEngine<any>
    self.subscriptionCallback = nil
    self.subscriptionOnce = nil

    return self
end
--[[ @end_section Subscription Methods ]]


--[[ @section Peek Methods ]]
--[[
    @usage Wraps a peek callback to the class.

    @param self AbstractedStateEngine<any>
    @param callback WrappedPeekCallbackType<AbstractedStateEngine<any>, any>
    @param once true?

    @return AbstractedStateEngine<any>
]]
local function wrapToPeekCallback
(
    self: AbstractedStateEngine<any>,
    callback: WrappedPeekCallbackType<AbstractedStateEngine<any>, any>,
    once: true?
): AbstractedStateEngine<any>
    self.peekCallback = callback
    self.peekObserveOnce = once

    return self
end

--[[
    @usage Unwraps a peek callback from the class.

    @param self AbstractedStateEngine<any>

    @return AbstractedStateEngine<any>
]]
local function unwrapToPeekCallback(self: AbstractedStateEngine<any>): AbstractedStateEngine<any>
    self.peekCallback = nil
    self.peekObserveOnce = nil

    return self
end
--[[ @end_section Peek Methods ]]


--[[ @section Lock Methods ]]
--[[
    @usage Locks the class, preventing further modifications.

    @param self AbstractedStateEngine<any>

    @return AbstractedStateEngine<any>
]]
local function lockCallback(self: AbstractedStateEngine<any>): AbstractedStateEngine<any>
    local TempMetatable = getmetatable(self) :: { [string]: any }
    table.freeze(TempMetatable)

    setmetatable(self, TempMetatable)
    table.freeze(self :: any)

    return self
end

--[[
    @usage Returns the unlocked class, allowing further modifications.

    @param self AbstractedStateEngine<any>

    @return AbstractedStateEngine<any>
]]
local function returnUnlockedCallback(self: AbstractedStateEngine<any>): AbstractedStateEngine<any>
    local UnlockedSelf = {}
    local UnlockedSelfMetatable = {}

    -- Deep clone the class and its metatable.
    do
        for i: string, v: any in pairs(self :: { [string]: any }) do
            UnlockedSelf[i] = v
        end

        for i: string, v: any in pairs(getmetatable(self) :: { [string]: any }) do
            UnlockedSelfMetatable[i] = v
        end

        setmetatable(UnlockedSelf, UnlockedSelfMetatable)
    end

    return UnlockedSelf :: AbstractedStateEngine<any>
end
--[[ @end_section Lock Methods ]]


--[[ @section State Engine Methods ]]
--[[
    @usage Returns the current state of the class or edits it.

    @generic_pack P... Path types.

    @generic D Data type.
    @generic K Key type.

    @param self AbstractedStateEngine<any>
    @param freshData D?
    @param freshKey K?
    @param ... P...

    @return (any | D) | AbstractedStateEngine<any>
]]
local function stateEngineCallback
<D, K, P...>(
    self: AbstractedStateEngine<any>,
    freshData: D?,
    freshKey: K?,
    ...: P...
): (any | D) | AbstractedStateEngine<any>
    -- Checks for nil or frozen data to just return the source.
    if freshData == nil or table.isfrozen(self :: any) then
        if not self.peekCallback or table.isfrozen(self :: any) then return self.source end
        self:peekCallback(self.source)

        if not self.peekObserveOnce then return self.source end
        self.peekCallback = nil; self.peekObserveOnce = nil
    end

    local Args = { ... }
    local numOfArgs = #Args

    -- Data modification handling.
    if not freshKey then self.source = freshData
    elseif numOfArgs == 0 and typeof(self.source) == "table" then self.source[freshKey] = freshData
    elseif numOfArgs >= 0 and typeof(self.source) == "table" then
        local CurrentPath = self.source

        for i: number, arg: any in ipairs(Args) do
            if not CurrentPath[arg] then CurrentPath[arg] = {} end
            CurrentPath = CurrentPath[arg]

            if i == numOfArgs and typeof(CurrentPath) == "table" then CurrentPath[freshKey] = freshData end
        end
    end

    -- Subscription handling.
    do
        if not self.subscriptionCallback then return self end

        if self.subscriptionCallback then self:subscriptionCallback(freshData, freshKey, ...) end
        if self.subscriptionOnce then self.subscriptionCallback = nil; self.subscriptionOnce = nil end
    end

    return self
end

--[[
    @usage Adds a method to the class.

    @param self AbstractedStateEngine<any>
    @param MethodDetails MethodDetailsSchema<AbstractedStateEngine<any>>

    @return AbstractedStateEngine<any>
]]
local function stateEngineAddCallback
(
    self: AbstractedStateEngine<any>,
    MethodDetails: MethodDetailsSchema<AbstractedStateEngine<any>>
): AbstractedStateEngine<any>
    if table.isfrozen(self :: any)
        or MethodDetails.methodName == "__call"
        or MethodDetails.methodName == "__index"
        or MethodDetails.methodName == "__add"
    then return self end

    local TempMetatable = getmetatable(self) :: { [string]: any }
    TempMetatable[MethodDetails.methodName] = MethodDetails.methodCallback
    setmetatable(self, TempMetatable)

    return self
end
--[[ @end_section State Engine Methods ]]


--[[
    @usage Returns the state details of the class.

    @param self AbstractedStateEngine<any>

    @return StateDetailsSchema
]]
local function getStateDetailsCallback(self: AbstractedStateEngine<any>): StateDetailsSchema
    return
    {
        isLocked = table.isfrozen(self :: any),
        isSubscribed = self.subscriptionCallback ~= nil,
        isPeekWrapped = self.peekCallback ~= nil
    }
end


--[[ @section State Engine Constructor ]]
--[[
    @usage Creates a new state engine.

    @generic S Source type.

    @param source S

    @return AbstractedStateEngine<S>
]]
local function stateEngineConstructor<S>(source: S): AbstractedStateEngine<S>
    local self = setmetatable(
        { source = source },

        {
            __index
            = {
                subscribe = subscribeCallback,
                unsubscribe = unsubscribeCallback,

                lock = lockCallback,
                returnUnlocked = returnUnlockedCallback,

                wrapToPeek = wrapToPeekCallback,
                unwrapToPeek = unwrapToPeekCallback,

                getStateDetails = getStateDetailsCallback
            },

            __call = stateEngineCallback,
            __add = stateEngineAddCallback
        }
    )

    return (self :: any) :: AbstractedStateEngine<S>
end

setmetatable(Reactor, { __call = stateEngineConstructor })
--[[ @end_section State Engine Constructor ]]


table.freeze(Reactor)
return Reactor
