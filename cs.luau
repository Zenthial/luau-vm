local CollectionService = game:GetService("CollectionService")

local function create_handler<T>(tag: string, instance: T, f: (T) -> (boolean, string?))
    local created, err = f(instance)
    if created == false then
        CollectionService:RemoveTag(instance, tag)
        if err ~= nil then
            warn(err)
        end
    end
end

local function on_create<T>(tag: string, f: (T) -> (boolean, string?))
    for _, instance in CollectionService:GetTagged(tag) do
        task.spawn(create_handler, tag, instance, f)
    end

    -- wait a frame to avoid double firing
	task.wait()

    CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance: T)
        create_handler(tag, instance, f)
    end)
end

local function on_destroy(tag: string, f: (Instance) -> ())
    CollectionService:GetInstanceRemovedSignal(tag):Connect(f)
end

return {
    on_destroy = on_destroy,
    on_create = on_create,
}
