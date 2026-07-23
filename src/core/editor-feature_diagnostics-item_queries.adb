with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Feature_Diagnostics.Display;
with Editor.Feature_Diagnostics.Labels;
with Editor.Feature_Diagnostics.Filtering;

package body Editor.Feature_Diagnostics.Item_Queries is

   function Severity_Label
     (Severity : Diagnostic_Severity) return String
     renames Editor.Feature_Diagnostics.Display.Severity_Label;

   function Source_Kind_Label
     (Source_Kind : Diagnostic_Source_Kind) return String
     renames Editor.Feature_Diagnostics.Display.Source_Kind_Label;

   function Source_Filter_Label_For
     (Item : Diagnostic_Item) return String
     renames Editor.Feature_Diagnostics.Display.Source_Filter_Label_For;

   function Label_For
     (Item : Diagnostic_Item) return String
     renames Editor.Feature_Diagnostics.Labels.Label_For;

   function Detail_For
     (Item : Diagnostic_Item) return String
     renames Editor.Feature_Diagnostics.Labels.Detail_For;

   function Normalize_Diagnostics_Filter_Text (Text : String) return String
     renames Editor.Feature_Diagnostics.Display.Normalize_Diagnostics_Filter_Text;

   function Item_At
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Diagnostic_Item
   is
   begin
      if Index = 0 or else Index > Row_Count (Diagnostics) then
         return (others => <>);
      end if;
      return Diagnostics.Rows.Element (Index - 1);
   end Item_At;

   function Contains_Case_Insensitive
     (Haystack : String;
      Needle   : String) return Boolean
   is
      Normal_Haystack : constant String := Normalize_Diagnostics_Filter_Text (Haystack);
      Normal_Needle   : constant String := Normalize_Diagnostics_Filter_Text (Needle);
   begin
      return Normal_Needle'Length = 0
        or else Ada.Strings.Fixed.Index (Normal_Haystack, Normal_Needle) /= 0;
   end Contains_Case_Insensitive;

   function Diagnostic_Matches_Text_Filter
     (Diagnostics : Diagnostics_Feature_State;
      Item        : Diagnostic_Item) return Boolean
   is
      Needle : constant String := To_String (Diagnostics.Filter.Text);
   begin
      if Needle'Length = 0 then
         return True;
      end if;

      return Contains_Case_Insensitive (To_String (Item.Message), Needle)
        or else Contains_Case_Insensitive (To_String (Item.Source_Label), Needle)
        or else Contains_Case_Insensitive (Severity_Label (Item.Severity), Needle)
        or else Contains_Case_Insensitive (Source_Kind_Label (Item.Source_Kind), Needle)
        or else Contains_Case_Insensitive (Label_For (Item), Needle)
        or else Contains_Case_Insensitive (Detail_For (Item), Needle);
   end Diagnostic_Matches_Text_Filter;

   function Diagnostic_Matches_Source_Label_Filter
     (Diagnostics : Diagnostics_Feature_State;
      Item        : Diagnostic_Item) return Boolean
   is
      Needle : constant String := To_String (Diagnostics.Filter.Source_Text);
   begin
      if Needle'Length = 0 then
         return True;
      end if;

      return Contains_Case_Insensitive (Source_Filter_Label_For (Item), Needle);
   end Diagnostic_Matches_Source_Label_Filter;

   function Diagnostic_Matches_Severity_Filter
     (Diagnostics : Diagnostics_Feature_State;
      Item        : Diagnostic_Item) return Boolean
   is
   begin
      case Item.Severity is
         when Diagnostic_Info    => return Diagnostics.Filter.Show_Info;
         when Diagnostic_Note    => return Diagnostics.Filter.Show_Notes;
         when Diagnostic_Warning => return Diagnostics.Filter.Show_Warnings;
         when Diagnostic_Error   => return Diagnostics.Filter.Show_Errors;
         when Diagnostic_Unknown => return Diagnostics.Filter.Show_Unknown_Severity;
      end case;
   end Diagnostic_Matches_Severity_Filter;

   function Diagnostic_Matches_Source_Filter
     (Diagnostics : Diagnostics_Feature_State;
      Item        : Diagnostic_Item) return Boolean
   is
   begin
      case Item.Source_Kind is
         when Editor_Diagnostic_Source   => return Diagnostics.Filter.Show_Editor;
         when File_Diagnostic_Source     => return Diagnostics.Filter.Show_File;
         when Project_Diagnostic_Source  => return Diagnostics.Filter.Show_Project;
         when External_Diagnostic_Source => return Diagnostics.Filter.Show_External;
         when Unknown_Diagnostic_Source  => return Diagnostics.Filter.Show_Unknown;
      end case;
   end Diagnostic_Matches_Source_Filter;

end Editor.Feature_Diagnostics.Item_Queries;
