with Editor.Ada_Declaration_Parser.Lexical_Helpers;

package body Editor.Ada_Declaration_Parser.Line_Dispatch is

   use Editor.Ada_Declaration_Parser.Lexical_Helpers;

   function Starts_With_Declaration_Or_Metadata
     (Decl_Lower : String) return Boolean is
   begin
      return Starts_With_Word (Decl_Lower, "package")
        or else Starts_With_Word (Decl_Lower, "procedure")
        or else Starts_With_Word (Decl_Lower, "function")
        or else Starts_With_Word (Decl_Lower, "type")
        or else Starts_With_Word (Decl_Lower, "subtype")
        or else Starts_With_Word (Decl_Lower, "task")
        or else Starts_With_Word (Decl_Lower, "protected")
        or else Starts_With_Word (Decl_Lower, "entry")
        or else Starts_With_Word (Decl_Lower, "generic")
        or else Starts_With_Word (Decl_Lower, "with")
        or else Starts_With_Word (Decl_Lower, "use")
        or else Starts_With_Word (Decl_Lower, "pragma")
        or else Starts_With_Word (Decl_Lower, "private")
        or else Starts_With_Word (Decl_Lower, "separate")
        or else Starts_With_Word (Decl_Lower, "overriding")
        or else Starts_With_Word (Decl_Lower, "not overriding")
        or else Starts_With_Word (Decl_Lower, "end")
        or else (Starts_With_Word (Decl_Lower, "for")
                 and then Has_Token (Decl_Lower, "use"));
   end Starts_With_Declaration_Or_Metadata;

end Editor.Ada_Declaration_Parser.Line_Dispatch;
