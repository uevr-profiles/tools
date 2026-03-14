local api = uevr.api
local vr = uevr.params.vr
uevr.sdk.callbacks.on_pre_engine_tick(
	function(engine, delta)

pawn=api:get_local_pawn(0)
pawn.Mesh.OverrideMaterials[1].BasePropertyOverrides.BlendMode=1
pawn.Mesh.OverrideMaterials[1].BasePropertyOverrides.bOverride_BlendMode=true
print(pawn.Mesh.OverrideMaterials[1].BasePropertyOverrides.BlendMode)
end)