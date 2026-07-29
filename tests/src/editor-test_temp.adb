with GNAT.OS_Lib;

with Hostkit.Fs;

package body Editor.Test_Temp is

   function Base return String is
      --  Ask hostkit for the host's temp directory rather than reading
      --  TMPDIR/TEMP/TMP by hand. On Windows that is GetTempPathA, which stays
      --  valid even when the process carries no temp variable, and it is never
      --  empty -- the same discovery the rest of the workspace already shares.
      Raw : constant String := Hostkit.Fs.Temp_Directory;

      --  Resolve_Links so the base matches the canonical form the editor
      --  produces: on macOS this is what turns /tmp into /private/tmp.
      Resolved : constant String :=
        GNAT.OS_Lib.Normalize_Pathname (Raw, Resolve_Links => True);
   begin
      --  Strip a trailing separator, so callers can append "/name" without doubling it.
      if Resolved'Length > 1
        and then (Resolved (Resolved'Last) = '/' or else Resolved (Resolved'Last) = '\')
      then
         return Resolved (Resolved'First .. Resolved'Last - 1);
      end if;

      return Resolved;
   end Base;

end Editor.Test_Temp;
