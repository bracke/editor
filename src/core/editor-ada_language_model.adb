with Editor.Ada_Language_Model.Hashing;
with Editor.Ada_Language_Model.Symbols;
with Editor.Ada_Language_Model.Generic_Metadata;
with Editor.Ada_Language_Model.Representation_Metadata;
with Editor.Ada_Language_Model.Diagnostics;
with Editor.Ada_Language_Model.Visibility;
with Editor.Ada_Language_Model.Syntax_Attachment;

package body Editor.Ada_Language_Model is

   procedure Clear (Analysis : in out Analysis_Result)
     renames Editor.Ada_Language_Model.Symbols.Clear;

   function Add_Symbol
     (Analysis           : in out Analysis_Result;
      Name               : String;
      Kind               : Symbol_Kind;
      Source_Span              : Source_Range;
      Declaration_Column : Positive := 1;
      Enclosing_Scope    : Scope_Id := Root_Scope;
      Parent_Symbol      : Symbol_Id := No_Symbol;
      Depth              : Natural := 0;
      Profile_Summary    : String := "";
      Flags              : Declaration_Flags := (others => False);
      Target_Name        : String := "") return Symbol_Id
     renames Editor.Ada_Language_Model.Symbols.Add_Symbol;

   function Symbol_Count (Analysis : Analysis_Result) return Natural
     renames Editor.Ada_Language_Model.Symbols.Symbol_Count;

   procedure Set_Symbol_Kind
     (Analysis : in out Analysis_Result;
      Id       : Symbol_Id;
      Kind     : Symbol_Kind)
     renames Editor.Ada_Language_Model.Symbols.Set_Symbol_Kind;

   procedure Set_Symbol_Target
     (Analysis    : in out Analysis_Result;
      Id          : Symbol_Id;
      Target_Name : String)
     renames Editor.Ada_Language_Model.Symbols.Set_Symbol_Target;

   procedure Set_Symbol_Profile
     (Analysis        : in out Analysis_Result;
      Id              : Symbol_Id;
      Profile_Summary : String)
     renames Editor.Ada_Language_Model.Symbols.Set_Symbol_Profile;

   procedure Mark_Symbol_Instantiation
     (Analysis : in out Analysis_Result;
      Id       : Symbol_Id)
     renames Editor.Ada_Language_Model.Symbols.Mark_Symbol_Instantiation;

   procedure Mark_Symbol_Representation_Clause
     (Analysis : in out Analysis_Result;
      Id       : Symbol_Id)
     renames Editor.Ada_Language_Model.Symbols.Mark_Symbol_Representation_Clause;

   procedure Mark_Symbol_Pragma_Metadata
     (Analysis : in out Analysis_Result;
      Id       : Symbol_Id)
     renames Editor.Ada_Language_Model.Symbols.Mark_Symbol_Pragma_Metadata;

   procedure Mark_Symbol_Aspect_Specification
     (Analysis : in out Analysis_Result;
      Id       : Symbol_Id)
     renames Editor.Ada_Language_Model.Symbols.Mark_Symbol_Aspect_Specification;

   procedure Mark_Symbol_Access_Subprogram_Metadata
     (Analysis : in out Analysis_Result;
      Id       : Symbol_Id)
     renames Editor.Ada_Language_Model.Symbols.Mark_Symbol_Access_Subprogram_Metadata;

   procedure Merge_Symbol_Flags
     (Analysis : in out Analysis_Result;
      Id       : Symbol_Id;
      Flags    : Declaration_Flags)
     renames Editor.Ada_Language_Model.Symbols.Merge_Symbol_Flags;

   procedure Mark_Symbol_Variant_Record_Metadata
     (Analysis : in out Analysis_Result;
      Id       : Symbol_Id)
     renames Editor.Ada_Language_Model.Symbols.Mark_Symbol_Variant_Record_Metadata;

   procedure Add_Generic_Actual
     (Analysis        : in out Analysis_Result;
      Instance_Symbol : Symbol_Id;
      Formal_Name     : String := "";
      Actual_Name     : String;
      Position        : Natural := 0;
      Source_Span           : Source_Range := (others => 1))
     renames Editor.Ada_Language_Model.Generic_Metadata.Add_Generic_Actual;

   function Generic_Actual_Count
     (Analysis        : Analysis_Result;
      Instance_Symbol : Symbol_Id := No_Symbol) return Natural
     renames Editor.Ada_Language_Model.Generic_Metadata.Generic_Actual_Count;

   function Generic_Actual_At
     (Analysis        : Analysis_Result;
      Instance_Symbol : Symbol_Id;
      Index           : Positive) return Generic_Actual_Info
     renames Editor.Ada_Language_Model.Generic_Metadata.Generic_Actual_At;

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
      Source_Span                         : Source_Range := (others => 1))
     renames Editor.Ada_Language_Model.Generic_Metadata.Add_Profile_Parameter_Metadata;

   function Profile_Parameter_Count
     (Analysis     : Analysis_Result;
      Owner_Symbol : Symbol_Id := No_Symbol) return Natural
     renames Editor.Ada_Language_Model.Generic_Metadata.Profile_Parameter_Count;

   function Profile_Parameter_At
     (Analysis     : Analysis_Result;
      Owner_Symbol : Symbol_Id;
      Index        : Positive) return Profile_Parameter_Info
     renames Editor.Ada_Language_Model.Generic_Metadata.Profile_Parameter_At;

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
      Source_Span                     : Source_Range := (others => 1))
     renames Editor.Ada_Language_Model.Generic_Metadata.Add_Generic_Formal_Type_Metadata;

   function Generic_Formal_Type_Metadata_Count
     (Analysis      : Analysis_Result;
      Formal_Symbol : Symbol_Id := No_Symbol) return Natural
     renames Editor.Ada_Language_Model.Generic_Metadata.Generic_Formal_Type_Metadata_Count;

   function Generic_Formal_Type_Metadata_At
     (Analysis      : Analysis_Result;
      Formal_Symbol : Symbol_Id;
      Index         : Positive) return Generic_Formal_Type_Info
     renames Editor.Ada_Language_Model.Generic_Metadata.Generic_Formal_Type_Metadata_At;

   procedure Add_Pragma_Metadata
     (Analysis             : in out Analysis_Result;
      Name                 : String;
      Placement            : Pragma_Placement_Kind;
      Scope                : Scope_Id := Root_Scope;
      Target_Name          : String := "";
      Argument_Count       : Natural := 0;
      Named_Argument_Count : Natural := 0;
      Source_Span                : Source_Range := (others => 1))
     renames Editor.Ada_Language_Model.Generic_Metadata.Add_Pragma_Metadata;

   function Pragma_Metadata_Count
     (Analysis  : Analysis_Result;
      Placement : Pragma_Placement_Kind := Pragma_Placement_Declaration;
      Any_Placement : Boolean := True) return Natural
     renames Editor.Ada_Language_Model.Generic_Metadata.Pragma_Metadata_Count;

   function Pragma_Metadata_At
     (Analysis  : Analysis_Result;
      Index     : Positive) return Pragma_Info
     renames Editor.Ada_Language_Model.Generic_Metadata.Pragma_Metadata_At;

   procedure Add_Representation_Clause
     (Analysis          : in out Analysis_Result;
      Target_Symbol     : Symbol_Id := No_Symbol;
      Target_Name       : String;
      Kind              : Representation_Clause_Kind;
      Attribute_Name    : String := "";
      Item_Text         : String;
      Source_Form       : Representation_Source_Form :=
        Representation_Source_Attribute_Definition;
      Has_Static_Value  : Boolean := False;
      Static_Value      : Natural := 0;
      Source_Span             : Source_Range)
     renames Editor.Ada_Language_Model.Representation_Metadata.Add_Representation_Clause;

   function Representation_Clause_Count
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id := No_Symbol) return Natural
     renames Editor.Ada_Language_Model.Representation_Metadata.Representation_Clause_Count;

   function Representation_Clause_At
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id;
      Index         : Positive) return Representation_Clause_Info
     renames Editor.Ada_Language_Model.Representation_Metadata.Representation_Clause_At;

   procedure Add_Enumeration_Representation_Literal
     (Analysis         : in out Analysis_Result;
      Target_Symbol    : Symbol_Id;
      Literal_Symbol   : Symbol_Id := No_Symbol;
      Literal_Name     : String;
      Value_Text       : String;
      Has_Static_Value : Boolean := False;
      Static_Value     : Natural := 0;
      Source_Span            : Source_Range)
     renames Editor.Ada_Language_Model.Representation_Metadata.Add_Enumeration_Representation_Literal;

   function Enumeration_Representation_Literal_Count
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id := No_Symbol) return Natural
     renames Editor.Ada_Language_Model.Representation_Metadata.Enumeration_Representation_Literal_Count;

   function Enumeration_Representation_Literal_At
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id;
      Index         : Positive) return Enumeration_Representation_Literal_Info
     renames Editor.Ada_Language_Model.Representation_Metadata.Enumeration_Representation_Literal_At;

   procedure Add_Record_Representation_Component
     (Analysis          : in out Analysis_Result;
      Target_Symbol     : Symbol_Id;
      Component_Symbol  : Symbol_Id := No_Symbol;
      Component_Name    : String;
      Storage_Unit_Text : String;
      First_Bit_Text    : String;
      Last_Bit_Text     : String;
      Source_Form       : Representation_Source_Form :=
        Representation_Source_Record_Component_Clause;
      Has_Static_Storage_Unit : Boolean := False;
      Static_Storage_Unit     : Natural := 0;
      Has_Static_First_Bit    : Boolean := False;
      Static_First_Bit        : Natural := 0;
      Has_Static_Last_Bit     : Boolean := False;
      Static_Last_Bit         : Natural := 0;
      Source_Span             : Source_Range)
     renames Editor.Ada_Language_Model.Representation_Metadata.Add_Record_Representation_Component;

   function Representation_Component_Count
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id := No_Symbol) return Natural
     renames Editor.Ada_Language_Model.Representation_Metadata.Representation_Component_Count;

   function Representation_Component_At
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id;
      Index         : Positive) return Representation_Component_Info
     renames Editor.Ada_Language_Model.Representation_Metadata.Representation_Component_At;

   procedure Add_Legality_Diagnostic
     (Analysis       : in out Analysis_Result;
      Kind           : Legality_Diagnostic_Kind;
      Message        : String;
      Severity       : Legality_Diagnostic_Severity := Legality_Error;
      Primary_Symbol : Symbol_Id := No_Symbol;
      Related_Symbol : Symbol_Id := No_Symbol;
      Source_Span          : Source_Range := (others => 1))
     renames Editor.Ada_Language_Model.Diagnostics.Add_Legality_Diagnostic;

   function Legality_Diagnostic_Count
     (Analysis : Analysis_Result;
      Severity : Legality_Diagnostic_Severity := Legality_Error) return Natural
     renames Editor.Ada_Language_Model.Diagnostics.Legality_Diagnostic_Count;

   function Legality_Diagnostic_At
     (Analysis : Analysis_Result;
      Index    : Positive) return Legality_Diagnostic_Info
     renames Editor.Ada_Language_Model.Diagnostics.Legality_Diagnostic_At;

   function Has_Legality_Diagnostics
     (Analysis : Analysis_Result;
      Severity : Legality_Diagnostic_Severity := Legality_Error) return Boolean
     renames Editor.Ada_Language_Model.Diagnostics.Has_Legality_Diagnostics;

   function Diagnostic_Count
     (Analysis : Analysis_Result;
      Severity : Legality_Diagnostic_Severity := Legality_Error) return Natural
     renames Editor.Ada_Language_Model.Diagnostics.Diagnostic_Count;

   function Diagnostic_At
     (Analysis : Analysis_Result;
      Index    : Positive) return Diagnostic_Info
     renames Editor.Ada_Language_Model.Diagnostics.Diagnostic_At;

   procedure Add_Freezing_Point
     (Analysis       : in out Analysis_Result;
      Target_Symbol  : Symbol_Id;
      Trigger_Symbol : Symbol_Id;
      Kind           : Freezing_Point_Kind;
      Reason         : String;
      Source_Span          : Source_Range)
     renames Editor.Ada_Language_Model.Representation_Metadata.Add_Freezing_Point;

   function Freezing_Point_Count
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id := No_Symbol) return Natural
     renames Editor.Ada_Language_Model.Representation_Metadata.Freezing_Point_Count;

   function Freezing_Point_At
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id;
      Index         : Positive) return Freezing_Point_Info
     renames Editor.Ada_Language_Model.Representation_Metadata.Freezing_Point_At;

   procedure Add_Executable_Binding
     (Analysis        : in out Analysis_Result;
      Kind            : Executable_Binding_Kind;
      Name            : String;
      Expression_Text : String := "";
      Scope           : Scope_Id := Root_Scope;
      Target_Symbol   : Symbol_Id := No_Symbol;
      Source_Span           : Source_Range := (others => 1))
     renames Editor.Ada_Language_Model.Symbols.Add_Executable_Binding;

   function Executable_Binding_Count
     (Analysis : Analysis_Result;
      Kind     : Executable_Binding_Kind := Binding_Any)
      return Natural
     renames Editor.Ada_Language_Model.Symbols.Executable_Binding_Count;

   function Executable_Binding_At
     (Analysis : Analysis_Result;
      Index    : Positive) return Executable_Binding_Info
     renames Editor.Ada_Language_Model.Symbols.Executable_Binding_At;

   function Has_Executable_Bindings (Analysis : Analysis_Result) return Boolean
     renames Editor.Ada_Language_Model.Symbols.Has_Executable_Bindings;

   function Symbol (Analysis : Analysis_Result; Id : Symbol_Id) return Symbol_Info
     renames Editor.Ada_Language_Model.Symbols.Symbol;

   function Symbol_At (Analysis : Analysis_Result; Index : Positive) return Symbol_Info
     renames Editor.Ada_Language_Model.Symbols.Symbol_At;

   function Child_Count
     (Analysis : Analysis_Result;
      Parent   : Symbol_Id) return Natural
     renames Editor.Ada_Language_Model.Symbols.Child_Count;

   function Child_At
     (Analysis : Analysis_Result;
      Parent   : Symbol_Id;
      Index    : Positive) return Symbol_Id
     renames Editor.Ada_Language_Model.Symbols.Child_At;

   function Overload_Count
     (Analysis : Analysis_Result;
      Scope    : Scope_Id;
      Name     : String) return Natural
     renames Editor.Ada_Language_Model.Symbols.Overload_Count;

   function Overload_At
     (Analysis : Analysis_Result;
      Scope    : Scope_Id;
      Name     : String;
      Index    : Positive) return Symbol_Id
     renames Editor.Ada_Language_Model.Symbols.Overload_At;

   procedure Mark_Generated_Source_Awareness (Analysis : in out Analysis_Result)
     renames Editor.Ada_Language_Model.Visibility.Mark_Generated_Source_Awareness;

   procedure Mark_Conditional_Source_Awareness (Analysis : in out Analysis_Result)
     renames Editor.Ada_Language_Model.Visibility.Mark_Conditional_Source_Awareness;

   procedure Mark_With_Clause_Awareness (Analysis : in out Analysis_Result)
     renames Editor.Ada_Language_Model.Visibility.Mark_With_Clause_Awareness;

   procedure Mark_Use_Clause_Awareness (Analysis : in out Analysis_Result)
     renames Editor.Ada_Language_Model.Visibility.Mark_Use_Clause_Awareness;

   procedure Add_Visibility_Clause
     (Analysis             : in out Analysis_Result;
      Kind                 : Visibility_Clause_Kind;
      Name                 : String;
      Scope                : Scope_Id := Root_Scope;
      Source_Span                : Source_Range := (others => 1);
      Is_Context_Clause    : Boolean := False;
      Has_Limited_Modifier : Boolean := False;
      Has_Private_Modifier : Boolean := False)
     renames Editor.Ada_Language_Model.Visibility.Add_Visibility_Clause;

   function Visibility_Clause_Count
     (Analysis : Analysis_Result;
      Scope    : Scope_Id := Scope_Id'Last) return Natural
     renames Editor.Ada_Language_Model.Visibility.Visibility_Clause_Count;

   function Visibility_Clause_At
     (Analysis : Analysis_Result;
      Scope    : Scope_Id;
      Index    : Positive) return Visibility_Clause_Info
     renames Editor.Ada_Language_Model.Visibility.Visibility_Clause_At;

   function Context_Clause_Count
     (Analysis : Analysis_Result) return Natural
     renames Editor.Ada_Language_Model.Visibility.Context_Clause_Count;

   function Context_Clause_At
     (Analysis : Analysis_Result;
      Index    : Positive) return Visibility_Clause_Info
     renames Editor.Ada_Language_Model.Visibility.Context_Clause_At;

   function Use_Clause_Count
     (Analysis : Analysis_Result;
      Scope    : Scope_Id := Scope_Id'Last) return Natural
     renames Editor.Ada_Language_Model.Visibility.Use_Clause_Count;

   function Use_Clause_At
     (Analysis : Analysis_Result;
      Scope    : Scope_Id;
      Index    : Positive) return Visibility_Clause_Info
     renames Editor.Ada_Language_Model.Visibility.Use_Clause_At;

   function Overflowed (Analysis : Analysis_Result) return Boolean
     renames Editor.Ada_Language_Model.Visibility.Overflowed;

   function Has_Generated_Source_Awareness (Analysis : Analysis_Result) return Boolean
     renames Editor.Ada_Language_Model.Visibility.Has_Generated_Source_Awareness;

   function Has_Conditional_Source_Awareness (Analysis : Analysis_Result) return Boolean
     renames Editor.Ada_Language_Model.Visibility.Has_Conditional_Source_Awareness;

   function Has_With_Clause_Awareness (Analysis : Analysis_Result) return Boolean
     renames Editor.Ada_Language_Model.Visibility.Has_With_Clause_Awareness;

   function Has_Use_Clause_Awareness (Analysis : Analysis_Result) return Boolean
     renames Editor.Ada_Language_Model.Visibility.Has_Use_Clause_Awareness;

   procedure Mark_Statement_Kind
     (Analysis : in out Analysis_Result;
      Kind     : Statement_Kind)
     renames Editor.Ada_Language_Model.Symbols.Mark_Statement_Kind;

   function Statement_Count
     (Analysis : Analysis_Result;
      Kind     : Statement_Kind) return Natural
     renames Editor.Ada_Language_Model.Symbols.Statement_Count;

   function Total_Statement_Count (Analysis : Analysis_Result) return Natural
     renames Editor.Ada_Language_Model.Symbols.Total_Statement_Count;

   function Has_Statement_Awareness (Analysis : Analysis_Result) return Boolean
     renames Editor.Ada_Language_Model.Symbols.Has_Statement_Awareness;

   procedure Set_Syntax_Tree
     (Analysis : in out Analysis_Result;
      Tree     : Editor.Ada_Syntax_Tree.Tree_Type)
     renames Editor.Ada_Language_Model.Syntax_Attachment.Set_Syntax_Tree;

   function Has_Syntax_Tree (Analysis : Analysis_Result) return Boolean
     renames Editor.Ada_Language_Model.Syntax_Attachment.Has_Syntax_Tree;

   function Syntax_Tree_Node_Count (Analysis : Analysis_Result) return Natural
     renames Editor.Ada_Language_Model.Syntax_Attachment.Syntax_Tree_Node_Count;

   function Syntax_Tree_Root_Kind
     (Analysis : Analysis_Result) return Editor.Ada_Syntax_Tree.Node_Kind
     renames Editor.Ada_Language_Model.Syntax_Attachment.Syntax_Tree_Root_Kind;

   function Syntax_Tree_Fingerprint (Analysis : Analysis_Result) return Natural
     renames Editor.Ada_Language_Model.Syntax_Attachment.Syntax_Tree_Fingerprint;

   function Syntax_Tree
     (Analysis : Analysis_Result) return Editor.Ada_Syntax_Tree.Tree_Type
     renames Editor.Ada_Language_Model.Syntax_Attachment.Syntax_Tree;

   function Fingerprint (Analysis : Analysis_Result) return Natural
     renames Editor.Ada_Language_Model.Syntax_Attachment.Fingerprint;

   function Normalize_Name (Name : String) return String
     renames Editor.Ada_Language_Model.Hashing.Normalize_Name;

   function Kind_To_Syntax_Kind (Kind : Symbol_Kind) return Editor.Syntax.Token_Kind
     renames Editor.Ada_Language_Model.Symbols.Kind_To_Syntax_Kind;

   function Is_Subprogram (Kind : Symbol_Kind) return Boolean
     renames Editor.Ada_Language_Model.Symbols.Is_Subprogram;

   function Is_Type_Like (Kind : Symbol_Kind) return Boolean
     renames Editor.Ada_Language_Model.Symbols.Is_Type_Like;

   function Is_Declaration_Owner (Kind : Symbol_Kind) return Boolean
     renames Editor.Ada_Language_Model.Symbols.Is_Declaration_Owner;

   function Is_Separate_Body_Parent_Target (Symbol : Symbol_Info) return Boolean
     renames Editor.Ada_Language_Model.Symbols.Is_Separate_Body_Parent_Target;

   function Scope_For_Position
     (Analysis : Analysis_Result;
      Line     : Positive;
      Column   : Positive) return Symbol_Id
     renames Editor.Ada_Language_Model.Symbols.Scope_For_Position;

end Editor.Ada_Language_Model;
