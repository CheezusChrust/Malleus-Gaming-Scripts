--Because driving props is the worst feature

print("antidrive loading...")
hook.Add( "CanProperty", "block_drive", function( ply, property, ent )
	if ( !ply:IsAdmin() && property == "drive" ) then return false end
end )