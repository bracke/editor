with Editor.Ada_Language_Model;
with Editor.Outline;

package Editor.Outline_Extractor.Symbols is

   function Outline_Kind_For_Symbol
     (Kind : Editor.Ada_Language_Model.Symbol_Kind)
      return Editor.Outline.Outline_Item_Kind;

   function Type_Label_Prefix
     (Symbol : Editor.Ada_Language_Model.Symbol_Info) return String;

   function Formal_Type_Label_Prefix
     (Symbol : Editor.Ada_Language_Model.Symbol_Info) return String;

   function Has_Return_Profile
     (Symbol : Editor.Ada_Language_Model.Symbol_Info) return Boolean;

   function Callable_Display_Name
     (Symbol : Editor.Ada_Language_Model.Symbol_Info) return String;

   function Formal_Subprogram_Label_Prefix
     (Symbol : Editor.Ada_Language_Model.Symbol_Info) return String;

   function Generic_Subprogram_Label_Prefix
     (Symbol : Editor.Ada_Language_Model.Symbol_Info) return String;

   function Symbol_Label
     (Symbol : Editor.Ada_Language_Model.Symbol_Info) return String;

   function Symbol_Has_Child_Kind
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Parent   : Editor.Ada_Language_Model.Symbol_Id;
      Kind     : Editor.Ada_Language_Model.Symbol_Kind) return Boolean;

   function Projected_Symbol_Label
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Symbol   : Editor.Ada_Language_Model.Symbol_Info) return String;

   function Symbol_Detail
     (Symbol : Editor.Ada_Language_Model.Symbol_Info) return String;

   function Include_Symbol_In_Outline
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Info     : Editor.Ada_Language_Model.Symbol_Info) return Boolean;

end Editor.Outline_Extractor.Symbols;
