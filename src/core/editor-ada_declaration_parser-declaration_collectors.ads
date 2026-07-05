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

end Editor.Ada_Declaration_Parser.Declaration_Collectors;
