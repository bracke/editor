with Editor.Feature_Panel;

package Editor.Feature_Diagnostics.Item_Queries is

   function Item_At
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Diagnostic_Item;

   function Contains_Case_Insensitive
     (Haystack : String;
      Needle   : String) return Boolean;

   function Diagnostic_Matches_Text_Filter
     (Diagnostics : Diagnostics_Feature_State;
      Item        : Diagnostic_Item) return Boolean;

   function Diagnostic_Matches_Source_Label_Filter
     (Diagnostics : Diagnostics_Feature_State;
      Item        : Diagnostic_Item) return Boolean;

   function Diagnostic_Matches_Severity_Filter
     (Diagnostics : Diagnostics_Feature_State;
      Item        : Diagnostic_Item) return Boolean;

   function Diagnostic_Matches_Source_Filter
     (Diagnostics : Diagnostics_Feature_State;
      Item        : Diagnostic_Item) return Boolean;

end Editor.Feature_Diagnostics.Item_Queries;
