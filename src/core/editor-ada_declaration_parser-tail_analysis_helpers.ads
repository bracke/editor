package Editor.Ada_Declaration_Parser.Tail_Analysis_Helpers is

   function Tail_Token_At
     (Lowered_Text : String;
      Pos          : Natural;
      Token        : String) return Boolean;

   function Previous_Token_Is_End
     (Lowered_Text : String;
      Pos          : Natural) return Boolean;

   function End_Followed_By
     (Lowered_Text : String;
      Pos          : Natural;
      Token        : String) return Boolean;

   function Tail_After_Arrow (Line : String) return String;

   function Tail_After_Leading_Word
     (Line, Word : String) return String;

   function Strip_Leading_Statement_Labels (Text : String) return String;

   function Strip_Leading_Named_Statement_Prefix
     (Text : String) return String;

   function Leading_Statement_Label_Count
     (Text : String) return Natural;

   function Compact_Selected_Name_At
     (Lowered_Text : String;
      Pos          : Natural) return String;

   function Is_Selected_Name_Blank (C : Character) return Boolean;

   function Compact_Selected_Name_At
     (Lowered_Text : String;
      Pos          : Natural;
      Max_Length   : Positive) return String;

   function Previous_Selected_Name_Before
     (Lowered_Text : String;
      Pos          : Natural) return String;

   function Anonymous_Declare_Name_At
     (Lowered_Text : String;
      Pos          : Natural) return String;

   function Compact_Package_Name_At
     (Lowered_Text : String;
      Pos          : Natural) return String;

   function Compact_Callable_Name_At
     (Lowered_Text : String;
      Pos          : Natural) return String;

   function Has_Nested_Compact_Scope_Opener
     (Lowered_Text : String;
      Pos          : Natural) return Boolean;

   function Generic_Anonymous_Declare_Name_At
     (Lowered_Text : String;
      Pos          : Natural) return String;

   function Generic_End_Followed_By
     (Lowered_Text : String;
      Pos          : Natural;
      Token        : String) return Boolean;

   function Generic_End_Is_Metadata_Or_Control
     (Lowered_Text : String;
      Pos          : Natural) return Boolean;

end Editor.Ada_Declaration_Parser.Tail_Analysis_Helpers;
