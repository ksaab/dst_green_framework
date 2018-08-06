return function(self, reactor, initiator)
    if self.reactParams and self.reactParams.effect and initiator and initiator.components.gfeffectable then
        initiator.components.gfeffectable:RemoveEffect(self.reactParams.effect)
    end
end