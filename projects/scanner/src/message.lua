local utils = require("utils")

local Message = {}

function Message.__init__(base, msg)
    uuid = utils.gen_uuid()
    self = {uuid=uuid, msg=msg}
    setmetatable(self, {__index=Message})
    return self
end
setmetatable(Message, {__call=Message.__init__})

function Message:as_table()
    return {uuid=self.uuid, msg=self.msg}
end

return Message
