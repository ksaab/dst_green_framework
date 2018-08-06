return function(self, reactor, initiator)
    if self.reactParams and self.reactParams.effect and initiator and initiator.components.gfeffectable then
        initiator.components.gfeffectable:ApplyEffect(self.reactParams.effect,
        {
            initiator = reactor,
            stacks = self.reactParams.stacks or 1,
            duration = self.reactParams.duration
        })
    end
end