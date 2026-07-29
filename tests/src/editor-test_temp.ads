package Editor.Test_Temp is

   --  The directory tests build their scratch files under -- the host's real temporary
   --  directory, with links resolved.
   --
   --  This exists because Editor.Test_Temp.Base & "" was hardcoded in dozens of test helpers, and that is
   --  wrong twice over. On Windows there is no /tmp at all. And on macOS /tmp is a symlink
   --  into /private/tmp, so a path built as Editor.Test_Temp.Path ("x") never string-compares equal to the
   --  "/private/tmp/x" the editor canonicalises it to -- which failed a hundred and
   --  eighty tests about paths and file associations, none of them a real defect.
   --
   --  Resolving the links here is the whole point: the base a test builds on is the base
   --  the editor will report back.
   function Base return String;

   --  Base joined with each '/'-separated segment of Relative using the host's
   --  own separator. Prefer this to `Base & "/x/y"`: that literal keeps forward
   --  slashes, and on Windows the editor stores a file's identity as
   --  Ada.Directories.Full_Name -- all backslashes -- so the concatenated form
   --  never string-compares equal to it and every path-identity assertion fails
   --  there while passing on Linux. Composing natively matches Full_Name on
   --  every host. Relative is always written with '/' regardless of platform.
   function Path (Relative : String) return String;

end Editor.Test_Temp;
