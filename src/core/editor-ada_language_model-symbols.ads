with Editor.Ada_Language_Model;
with Editor.Syntax;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Language_Model.Symbols is

   procedure Clear (Analysis : in out Analysis_Result);

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
      Target_Name        : String := "") return Symbol_Id;

   function Symbol_Count (Analysis : Analysis_Result) return Natural;

   procedure Set_Symbol_Kind
     (Analysis : in out Analysis_Result;
      Id       : Symbol_Id;
      Kind     : Symbol_Kind);

   procedure Set_Symbol_Target
     (Analysis    : in out Analysis_Result;
      Id          : Symbol_Id;
      Target_Name : String);

   procedure Set_Symbol_Profile
     (Analysis        : in out Analysis_Result;
      Id              : Symbol_Id;
      Profile_Summary : String);

   procedure Mark_Symbol_Instantiation
     (Analysis : in out Analysis_Result;
      Id       : Symbol_Id);

   procedure Mark_Symbol_Representation_Clause
     (Analysis : in out Analysis_Result;
      Id       : Symbol_Id);

   procedure Mark_Symbol_Pragma_Metadata
     (Analysis : in out Analysis_Result;
      Id       : Symbol_Id);

   procedure Mark_Symbol_Aspect_Specification
     (Analysis : in out Analysis_Result;
      Id       : Symbol_Id);

   procedure Mark_Symbol_Access_Subprogram_Metadata
     (Analysis : in out Analysis_Result;
      Id       : Symbol_Id);

   procedure Merge_Symbol_Flags
     (Analysis : in out Analysis_Result;
      Id       : Symbol_Id;
      Flags    : Declaration_Flags);

   procedure Mark_Symbol_Variant_Record_Metadata
     (Analysis : in out Analysis_Result;
      Id       : Symbol_Id);


   procedure Mark_Statement_Kind
     (Analysis : in out Analysis_Result;
      Kind     : Statement_Kind);

   function Statement_Count
     (Analysis : Analysis_Result;
      Kind     : Statement_Kind) return Natural;

   function Total_Statement_Count (Analysis : Analysis_Result) return Natural;
   function Has_Statement_Awareness (Analysis : Analysis_Result) return Boolean;

   procedure Add_Executable_Binding
     (Analysis        : in out Analysis_Result;
      Kind            : Executable_Binding_Kind;
      Name            : String;
      Expression_Text : String := "";
      Scope           : Scope_Id := Root_Scope;
      Target_Symbol   : Symbol_Id := No_Symbol;
      Source_Span           : Source_Range := (others => 1));

   function Executable_Binding_Count
     (Analysis : Analysis_Result;
      Kind     : Executable_Binding_Kind := Binding_Any)
      return Natural;

   function Executable_Binding_At
     (Analysis : Analysis_Result;
      Index    : Positive) return Executable_Binding_Info;

   function Has_Executable_Bindings (Analysis : Analysis_Result) return Boolean;

   function Symbol (Analysis : Analysis_Result; Id : Symbol_Id) return Symbol_Info;
   function Symbol_At (Analysis : Analysis_Result; Index : Positive) return Symbol_Info;

   function Child_Count
     (Analysis : Analysis_Result;
      Parent   : Symbol_Id) return Natural;

   function Child_At
     (Analysis : Analysis_Result;
      Parent   : Symbol_Id;
      Index    : Positive) return Symbol_Id;

   function Overload_Count
     (Analysis : Analysis_Result;
      Scope    : Scope_Id;
      Name     : String) return Natural;

   function Overload_At
     (Analysis : Analysis_Result;
      Scope    : Scope_Id;
      Name     : String;
      Index    : Positive) return Symbol_Id;

   function Kind_To_Syntax_Kind (Kind : Symbol_Kind) return Editor.Syntax.Token_Kind;
   function Is_Subprogram (Kind : Symbol_Kind) return Boolean;
   function Is_Type_Like (Kind : Symbol_Kind) return Boolean;
   function Is_Declaration_Owner (Kind : Symbol_Kind) return Boolean;
   function Is_Separate_Body_Parent_Target (Symbol : Symbol_Info) return Boolean;

   --  Conservative lexical-scope bridge for semantic colouring.  Returns the
   --  deepest declaration-owning symbol that starts before the requested
   --  source position and contains it when a retained range is available, or
   --  No_Symbol for root scope.  This is intentionally bounded by the retained
   --  analysis and degrades to root when ownership metadata is incomplete.
   function Scope_For_Position
     (Analysis : Analysis_Result;
      Line     : Positive;
      Column   : Positive) return Symbol_Id;


end Editor.Ada_Language_Model.Symbols;
