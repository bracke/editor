with Ada.Containers.Vectors;

package Editor.Feature_Diagnostics.Filtering is

   package Visible_Row_Index_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Natural);

   function Diagnostic_Is_Visible
     (Diagnostics : Diagnostics_Feature_State;
      Item        : Diagnostic_Item) return Boolean;

   function Ordered_Visible_Indexes
     (Diagnostics : Diagnostics_Feature_State)
      return Visible_Row_Index_Vectors.Vector;

   function Visible_Row_Count
     (Diagnostics : Diagnostics_Feature_State) return Natural;

   function Severity_Is_Visible
     (Diagnostics : Diagnostics_Feature_State;
      Severity    : Diagnostic_Severity) return Boolean;

   function Source_Is_Visible
     (Diagnostics : Diagnostics_Feature_State;
      Source_Kind : Diagnostic_Source_Kind) return Boolean;

   function Filter_Active
     (Diagnostics : Diagnostics_Feature_State) return Boolean;

   function Filter_Text
     (Diagnostics : Diagnostics_Feature_State) return String;

   procedure Set_Filter_Text
     (Diagnostics : in out Diagnostics_Feature_State;
      Text        : String);

   procedure Clear_Filter
     (Diagnostics : in out Diagnostics_Feature_State);

   procedure Show_All
     (Diagnostics : in out Diagnostics_Feature_State);

   procedure Toggle_Info_Visible
     (Diagnostics : in out Diagnostics_Feature_State);

   procedure Toggle_Warnings_Visible
     (Diagnostics : in out Diagnostics_Feature_State);

   procedure Toggle_Errors_Visible
     (Diagnostics : in out Diagnostics_Feature_State);

   procedure Toggle_Source_Visible
     (Diagnostics : in out Diagnostics_Feature_State;
      Source_Kind : Diagnostic_Source_Kind);

   function Count_By_Severity
     (Diagnostics : Diagnostics_Feature_State) return Diagnostics_Severity_Counts;

   function Count_Label
     (Counts : Diagnostics_Severity_Counts) return String;

   function Visible_Count_Label
     (Counts : Diagnostics_Severity_Counts) return String;

   function Visible_File_Groups
     (Diagnostics : Diagnostics_Feature_State)
      return Diagnostics_File_Group_Vectors.Vector;

   function File_Group_Count
     (Diagnostics : Diagnostics_Feature_State) return Natural;

   function File_Group_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String;

   function Header_Text
     (Diagnostics : Diagnostics_Feature_State) return String;

   function Has_Visible_Diagnostic
     (Diagnostics : Diagnostics_Feature_State) return Boolean;

   function Build_Diagnostic_Count
     (Diagnostics : Diagnostics_Feature_State) return Natural;

   function Has_Diagnostic_With_Severity
     (Diagnostics : Diagnostics_Feature_State;
      Severity    : Diagnostic_Severity) return Boolean;

   function Has_Info_Or_Note_Diagnostic
     (Diagnostics : Diagnostics_Feature_State) return Boolean;

   function Has_Build_Diagnostic
     (Diagnostics : Diagnostics_Feature_State) return Boolean;

   procedure Filter_Errors_Only
     (Diagnostics : in out Diagnostics_Feature_State);

   procedure Filter_Warnings_Only
     (Diagnostics : in out Diagnostics_Feature_State);

   procedure Filter_Info_And_Notes_Only
     (Diagnostics : in out Diagnostics_Feature_State);

   procedure Filter_Build_Produced
     (Diagnostics : in out Diagnostics_Feature_State);

   procedure Filter_Source_Label
     (Diagnostics : in out Diagnostics_Feature_State;
      Source_Text : String);

end Editor.Feature_Diagnostics.Filtering;
