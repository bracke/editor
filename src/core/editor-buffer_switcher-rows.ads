with Editor.Buffer_Switcher_Model.Rows;

package Editor.Buffer_Switcher.Rows is

   subtype Buffer_Project_Ownership_Kind is
     Editor.Buffer_Switcher_Model.Rows.Buffer_Project_Ownership_Kind;
   subtype Buffer_Switcher_Row is
     Editor.Buffer_Switcher_Model.Rows.Buffer_Switcher_Row;

   Buffer_Project_Unknown : constant Buffer_Project_Ownership_Kind :=
     Editor.Buffer_Switcher_Model.Rows.Buffer_Project_Unknown;
   Buffer_Project_Owned : constant Buffer_Project_Ownership_Kind :=
     Editor.Buffer_Switcher_Model.Rows.Buffer_Project_Owned;
   Buffer_Project_Outside : constant Buffer_Project_Ownership_Kind :=
     Editor.Buffer_Switcher_Model.Rows.Buffer_Project_Outside;
   Buffer_Project_Scratch : constant Buffer_Project_Ownership_Kind :=
     Editor.Buffer_Switcher_Model.Rows.Buffer_Project_Scratch;
   Buffer_Project_No_Project : constant Buffer_Project_Ownership_Kind :=
     Editor.Buffer_Switcher_Model.Rows.Buffer_Project_No_Project;

end Editor.Buffer_Switcher.Rows;
