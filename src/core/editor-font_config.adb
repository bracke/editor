with Ada.Directories;
with Ada.Environment_Variables;

package body Editor.Font_Config is

   Candidates : constant array (Positive range <>) of access constant String :=
     [--  Linux
      new String'("/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"),
      new String'("/usr/share/fonts/truetype/noto/NotoSansMono-Regular.ttf"),
      new String'("/usr/share/fonts/truetype/liberation/LiberationMono-Regular.ttf"),
      new String'("/usr/share/fonts/TTF/DejaVuSansMono.ttf"),
      --  macOS
      new String'("/System/Library/Fonts/Menlo.ttc"),
      new String'("/System/Library/Fonts/Monaco.ttf"),
      --  Windows
      new String'("C:\Windows\Fonts\consola.ttf"),
      new String'("C:\Windows\Fonts\cour.ttf")];

   function Exists (Path : String) return Boolean is
   begin
      return Ada.Directories.Exists (Path);
   exception
      when others =>
         --  A path this host cannot even represent does not exist; it does not raise.
         return False;
   end Exists;

   function Font_Path return String is
      Override : constant String :=
        (if Ada.Environment_Variables.Exists ("EDITOR_FONT_PATH")
         then Ada.Environment_Variables.Value ("EDITOR_FONT_PATH")
         else "");
   begin
      if Override /= "" and then Exists (Override) then
         return Override;
      end if;

      for Candidate of Candidates loop
         if Exists (Candidate.all) then
            return Candidate.all;
         end if;
      end loop;

      --  Nothing found. Answer with the first candidate rather than an empty string, so
      --  the failure surfaces as "this font would not load" naming a path, rather than
      --  as an empty path that says nothing.
      return Candidates (Candidates'First).all;
   end Font_Path;

end Editor.Font_Config;
