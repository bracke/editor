with Editor.Ada_Language_Model;
with Editor.Syntax;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Language_Model.Generic_Metadata is

   procedure Add_Generic_Actual
     (Analysis        : in out Analysis_Result;
      Instance_Symbol : Symbol_Id;
      Formal_Name     : String := "";
      Actual_Name     : String;
      Position        : Natural := 0;
      Source_Span           : Source_Range := (others => 1));

   function Generic_Actual_Count
     (Analysis        : Analysis_Result;
      Instance_Symbol : Symbol_Id := No_Symbol) return Natural;

   function Generic_Actual_At
     (Analysis        : Analysis_Result;
      Instance_Symbol : Symbol_Id;
      Index           : Positive) return Generic_Actual_Info;

   procedure Add_Profile_Parameter_Metadata
     (Analysis                      : in out Analysis_Result;
      Owner_Symbol                  : Symbol_Id;
      Parameter_Symbol              : Symbol_Id;
      Name                          : String;
      Mode                          : Profile_Parameter_Mode;
      Type_Text                     : String := "";
      Has_Aliased                   : Boolean := False;
      Has_Access_Definition         : Boolean := False;
      Has_Access_Subprogram_Profile : Boolean := False;
      Has_Default_Expression        : Boolean := False;
      Default_Text                  : String := "";
      Group_Index                   : Natural := 0;
      Group_Position                : Natural := 0;
      Group_Name_Count              : Natural := 0;
      Source_Span                         : Source_Range := (others => 1));

   function Profile_Parameter_Count
     (Analysis     : Analysis_Result;
      Owner_Symbol : Symbol_Id := No_Symbol) return Natural;

   function Profile_Parameter_At
     (Analysis     : Analysis_Result;
      Owner_Symbol : Symbol_Id;
      Index        : Positive) return Profile_Parameter_Info;

   procedure Add_Generic_Formal_Type_Metadata
     (Analysis                  : in out Analysis_Result;
      Formal_Symbol             : Symbol_Id;
      Name                      : String;
      Family                    : Generic_Formal_Type_Family;
      Target_Type_Text          : String := "";
      Profile_Text              : String := "";
      Has_Private               : Boolean := False;
      Has_Limited               : Boolean := False;
      Has_Tagged                : Boolean := False;
      Has_Abstract              : Boolean := False;
      Has_Synchronized          : Boolean := False;
      Has_Interface             : Boolean := False;
      Has_Box                   : Boolean := False;
      Has_Discriminant_Part     : Boolean := False;
      Source_Span                     : Source_Range := (others => 1));

   function Generic_Formal_Type_Metadata_Count
     (Analysis      : Analysis_Result;
      Formal_Symbol : Symbol_Id := No_Symbol) return Natural;

   function Generic_Formal_Type_Metadata_At
     (Analysis      : Analysis_Result;
      Formal_Symbol : Symbol_Id;
      Index         : Positive) return Generic_Formal_Type_Info;

   procedure Add_Pragma_Metadata
     (Analysis             : in out Analysis_Result;
      Name                 : String;
      Placement            : Pragma_Placement_Kind;
      Scope                : Scope_Id := Root_Scope;
      Target_Name          : String := "";
      Argument_Count       : Natural := 0;
      Named_Argument_Count : Natural := 0;
      Source_Span                : Source_Range := (others => 1));

   function Pragma_Metadata_Count
     (Analysis  : Analysis_Result;
      Placement : Pragma_Placement_Kind := Pragma_Placement_Declaration;
      Any_Placement : Boolean := True) return Natural;

   function Pragma_Metadata_At
     (Analysis  : Analysis_Result;
      Index     : Positive) return Pragma_Info;



end Editor.Ada_Language_Model.Generic_Metadata;
