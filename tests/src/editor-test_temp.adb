with Ada.Directories;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with GNAT.OS_Lib;

with Hostkit.Fs;
with Hostkit.Host;

package body Editor.Test_Temp is

   use type Hostkit.Host.Kind;

   Host_Separator : constant Character :=
     (if Hostkit.Host.Current = Hostkit.Host.Windows then '\' else '/');

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

   function Join (Base : String; Relative : String) return String is
      Result : Unbounded_String := To_Unbounded_String (Base);
      First  : Positive := Relative'First;

      procedure Add (Segment : String) is
      begin
         --  Skip empty segments from a leading, trailing or doubled '/'.
         if Segment'Length > 0 then
            begin
               Result := To_Unbounded_String
                 (Ada.Directories.Compose (To_String (Result), Segment));
            exception
               when others =>
                  --  Ada.Directories.Compose rejects names it deems invalid
                  --  simple names (a drive letter "C:...", or malformed data a
                  --  test deliberately feeds as a path segment, e.g. containing
                  --  '|' or '='). Join must not raise on those: fall back to a
                  --  plain host-separator append, which yields the same native
                  --  form for ordinary names.
                  Append (Result, Host_Separator);
                  Append (Result, Segment);
            end;
         end if;
      end Add;
   begin
      for I in Relative'Range loop
         if Relative (I) = '/' then
            Add (Relative (First .. I - 1));
            First := I + 1;
         end if;
      end loop;
      Add (Relative (First .. Relative'Last));
      return To_String (Result);
   end Join;

   function Path (Relative : String) return String is
   begin
      return Join (Base, Relative);
   end Path;

end Editor.Test_Temp;
