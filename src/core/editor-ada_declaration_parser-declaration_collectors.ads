with Editor.Ada_Language_Model;

package Editor.Ada_Declaration_Parser.Declaration_Collectors is

   use Editor.Ada_Language_Model;

   Max_Collected_Object_Names : constant Natural := 16;
   type Collected_Symbol_List is
     array (1 .. Max_Collected_Object_Names) of Symbol_Id;

   procedure Add_Object_Names_Collecting
     (Analysis        : in out Analysis_Result;
      Raw_Line        : String;
      Line_Number     : Positive;
      Depth           : Natural;
      Parent          : Symbol_Id;
      Kind            : Symbol_Kind;
      Type_Target     : String;
      Collected       : in out Collected_Symbol_List;
      Collected_Count : in out Natural;
      Column_Base     : Natural := 0;
      Flags           : Declaration_Flags := (others => False));

   procedure Add_Object_Names
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Parent      : Symbol_Id;
      Kind        : Symbol_Kind;
      Type_Target : String;
      Column_Base : Natural := 0;
      Flags       : Declaration_Flags := (others => False));

   procedure Add_Object_Names
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Parent      : Symbol_Id;
      Kind        : Symbol_Kind;
      Column_Base : Natural := 0;
      Flags       : Declaration_Flags := (others => False));

   procedure Add_Object_Name_Groups
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Parent      : Symbol_Id;
      Kind        : Symbol_Kind;
      Column_Base : Natural := 0;
      Flags       : Declaration_Flags := (others => False));

   procedure Add_Discriminant_Names
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Parent      : Symbol_Id);

   procedure Add_Record_Component_Names
     (Analysis      : in out Analysis_Result;
      Raw_Line      : String;
      Line_Number   : Positive;
      Depth         : Natural;
      Parent        : Symbol_Id;
      Mark_Metadata : not null access procedure
        (Flags : in out Declaration_Flags;
         Line  : String));

   procedure Add_Object_Rename_Declaration_Groups
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Parent      : Symbol_Id);

   procedure Add_Object_Declaration_Groups
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Parent      : Symbol_Id;
      Kind        : Symbol_Kind;
      Flags       : Declaration_Flags := (others => False));

   procedure Add_Enumeration_Literals
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Parent      : Symbol_Id);

   procedure Add_Enumeration_Literals_Continuation
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Parent      : Symbol_Id);

end Editor.Ada_Declaration_Parser.Declaration_Collectors;
