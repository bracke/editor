with Editor.Ada_Token_Cursor.Parsing_Phases;

package body Editor.Ada_Token_Cursor is

   package Phases renames Editor.Ada_Token_Cursor.Parsing_Phases;

   function Parse (Text : String) return Grammar_Result is
   begin
      return Phases.Parse (Text);
   end Parse;

   function Production_Count (Result : Grammar_Result) return Natural is
   begin
      return Phases.Production_Count (Result);
   end Production_Count;

   function Production_At
     (Result : Grammar_Result;
      Index  : Positive) return Production_Info is
   begin
      return Phases.Production_At (Result, Index);
   end Production_At;

   function Has_Production
     (Result : Grammar_Result;
      Kind   : Production_Kind) return Boolean is
   begin
      return Phases.Has_Production (Result, Kind);
   end Has_Production;

end Editor.Ada_Token_Cursor;
