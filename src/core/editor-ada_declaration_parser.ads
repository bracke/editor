with Editor.Ada_Language_Model;

package Editor.Ada_Declaration_Parser is

   --  Parse an immutable Ada source snapshot into the shared in-process
   --  language model.  The parser is deterministic, bounded, and consumes only
   --  caller-supplied text; it performs no rendering, file I/O, saves, reloads,
   --  workspace mutation, or command execution.
   function Parse
     (Text         : String;
      Buffer_Label : String := "") return Editor.Ada_Language_Model.Analysis_Result;

end Editor.Ada_Declaration_Parser;
