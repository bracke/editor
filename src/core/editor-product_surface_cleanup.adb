with Ada.Characters.Handling;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Editor.Build_Candidates;
with Editor.Diagnostics;
with Editor.Feature_Panel;
with Editor.Feature_Search_Results;
with Editor.File_Tree;
with Editor.Outline;
with Editor.Project_Search;
with Editor.Quick_Open;

package body Editor.Product_Surface_Cleanup is

   use type Editor.Commands.Command_Visibility;
   use type Editor.Outline.Outline_Source_Class;
   use type Editor.Outline.Outline_Target_Kind;
   use type Editor.Build_Candidates.Build_Candidate_Kind;
   use type Editor.Build_Candidates.Build_Candidate_Source;
   use type Editor.Build_Candidates.Build_Candidate_Validation_Status;
   use type Editor.File_Tree.File_Tree_Node_Id;

   function US (Text : Ada.Strings.Unbounded.Unbounded_String) return String is
   begin
      return Ada.Strings.Unbounded.To_String (Text);
   end US;

   function Lower (Text : String) return String is
      Result : String := Text;
   begin
      for I in Result'Range loop
         Result (I) := Ada.Characters.Handling.To_Lower (Result (I));
      end loop;
      return Result;
   end Lower;

   function Contains (Haystack : String; Needle : String) return Boolean is
   begin
      return Ada.Strings.Fixed.Index (Haystack, Needle) /= 0;
   end Contains;

   function Looks_Like_Demo_Text (Text : String) return Boolean is
      L : constant String := Lower (Text);
   begin
      return Contains (L, "placeholder")
        or else Contains (L, "test/demo")
        or else Contains (L, " fake")
        or else Contains (L, "fake ")
        or else L = "fake"
        or else Contains (L, " demo")
        or else Contains (L, "demo ")
        or else L = "demo"
        or else Contains (L, "scaffold");
   end Looks_Like_Demo_Text;

   function Is_Test_Only_Command
     (Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      return Editor.Commands.Is_Test_Only_Command (Id);
   end Is_Test_Only_Command;

   function Feature_Panel_Has_Demo_Rows
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      for I in 1 .. Editor.Feature_Panel.Row_Count (S.Feature_Panel) loop
         if Looks_Like_Demo_Text
           (Editor.Feature_Panel.Row_Label (S.Feature_Panel, I))
           or else Looks_Like_Demo_Text
             (Editor.Feature_Panel.Row_Detail (S.Feature_Panel, I))
         then
            return True;
         end if;
      end loop;
      return False;
   end Feature_Panel_Has_Demo_Rows;

   function Outline_Has_Fixture_Data
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      for I in 1 .. Editor.Outline.Item_Count (S.Outline) loop
         if Looks_Like_Demo_Text
             (Editor.Outline.Item_Label (S.Outline, I))
         then
            return True;
         end if;
      end loop;
      return False;
   end Outline_Has_Fixture_Data;


   function Diagnostics_Has_Demo_Rows
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      for I in 1 .. Editor.Diagnostics.Diagnostic_Count (S.Diagnostics) loop
         if Looks_Like_Demo_Text
           (US (Editor.Diagnostics.Diagnostic_At (S.Diagnostics, I).Message))
         then
            return True;
         end if;
      end loop;
      return False;
   end Diagnostics_Has_Demo_Rows;

   function Build_UI_Has_Demo_State
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      if Looks_Like_Demo_Text (US (S.Build_UI.Build_Target_Label))
        or else Looks_Like_Demo_Text (US (S.Build_UI.Build_Working_Context_Label))
        or else Looks_Like_Demo_Text (US (S.Build_UI.Candidate_Request_Preview))
        or else Looks_Like_Demo_Text (US (S.Build_UI.Candidate_Selection_Message))
        or else Looks_Like_Demo_Text (US (S.Build_UI.Candidate_Discovery_Message))
        or else Looks_Like_Demo_Text (US (S.Build_UI.Candidate_Refresh_Message))
      then
         return True;
      end if;

      for Candidate of S.Build_UI.Build_Candidates loop
         if Candidate.Candidate_Kind = Editor.Build_Candidates.Build_Candidate_None
           or else Candidate.Discovery_Source = Editor.Build_Candidates.Build_Candidate_Source_None
           or else Looks_Like_Demo_Text (US (Candidate.Candidate_Id))
           or else Looks_Like_Demo_Text (US (Candidate.Display_Label))
           or else Looks_Like_Demo_Text (US (Candidate.Source_Path_If_Represented))
           or else Looks_Like_Demo_Text (US (Candidate.Validation_Message))
         then
            return True;
         end if;
      end loop;

      return False;
   end Build_UI_Has_Demo_State;

   function Search_Has_Demo_Results
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      for I in 1 .. Editor.Feature_Search_Results.Row_Count
        (S.Feature_Search_Results)
      loop
         if Looks_Like_Demo_Text
           (Editor.Feature_Search_Results.Item_Label
              (S.Feature_Search_Results, I))
           or else Looks_Like_Demo_Text
             (Editor.Feature_Search_Results.Item_Source_Label
                (S.Feature_Search_Results, I))
           or else Looks_Like_Demo_Text
             (Editor.Feature_Search_Results.Item_Line_Text
                (S.Feature_Search_Results, I))
         then
            return True;
         end if;
      end loop;

      for I in 1 .. Editor.Project_Search.Result_Count (S.Project_Search) loop
         declare
            R : constant Editor.Project_Search.Project_Search_Result :=
              Editor.Project_Search.Result_At (S.Project_Search, I);
         begin
            if Looks_Like_Demo_Text (US (R.Relative_Path))
              or else Looks_Like_Demo_Text (US (R.Absolute_Path))
              or else Looks_Like_Demo_Text (US (R.Line_Text))
              or else Looks_Like_Demo_Text (US (R.Line_Preview))
            then
               return True;
            end if;
         end;
      end loop;

      return False;
   end Search_Has_Demo_Results;

   function Quick_Open_Has_Demo_Results
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      for I in 1 .. Editor.Quick_Open.Result_Count (S.Quick_Open) loop
         declare
            R : constant Editor.Quick_Open.Quick_Open_Result :=
              Editor.Quick_Open.Result_At (S.Quick_Open, I);
         begin
            if Looks_Like_Demo_Text (US (R.Display_Path))
              or else Looks_Like_Demo_Text (US (R.Absolute_Path))
            then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Quick_Open_Has_Demo_Results;

   function File_Tree_Has_Demo_Nodes
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      for I in 1 .. Editor.File_Tree.Node_Count (S.File_Tree) loop
         declare
            N : constant Editor.File_Tree.File_Tree_Node_Summary :=
              Editor.File_Tree.Node (S.File_Tree, Editor.File_Tree.File_Tree_Node_Id (I));
         begin
            if N.Id /= Editor.File_Tree.No_File_Tree_Node
              and then
                (Looks_Like_Demo_Text (US (N.Name))
                 or else Looks_Like_Demo_Text (US (N.Absolute_Path))
                 or else Looks_Like_Demo_Text (US (N.Relative_Path)))
            then
               return True;
            end if;
         end;
      end loop;
      return False;
   end File_Tree_Has_Demo_Nodes;

   function Demo_Command_Exposed_To_Product_Surface return Boolean is
   begin
      for Id in Editor.Commands.Command_Id loop
         if Is_Test_Only_Command (Id) then
            declare
               D : constant Editor.Commands.Command_Descriptor :=
                 Editor.Commands.Descriptor (Id);
            begin
               if D.Visibility = Editor.Commands.Palette_Command
                 or else Editor.Commands.Is_Bindable_Command (Id)
               then
                  return True;
               end if;
            end;
         end if;
      end loop;
      return False;
   end Demo_Command_Exposed_To_Product_Surface;

   function Audit_Product_Surface_No_Demo_State
     (S : Editor.State.State_Type) return Product_Surface_Cleanup_Result
   is
      Result : Product_Surface_Cleanup_Result;
   begin
      Result.Feature_Panel_Clean := not Feature_Panel_Has_Demo_Rows (S);
      Result.Outline_Clean := not Outline_Has_Fixture_Data (S);
      Result.Diagnostics_Clean := not Diagnostics_Has_Demo_Rows (S);
      Result.Command_Surface_Clean := not Demo_Command_Exposed_To_Product_Surface;
      Result.Build_UI_Clean := not Build_UI_Has_Demo_State (S);
      Result.Search_Clean := not Search_Has_Demo_Results (S);
      Result.Quick_Open_Clean := not Quick_Open_Has_Demo_Results (S);
      Result.File_Tree_Clean := not File_Tree_Has_Demo_Nodes (S);
      Result.Coherent := Result.Feature_Panel_Clean
        and then Result.Outline_Clean
        and then Result.Diagnostics_Clean
        and then Result.Command_Surface_Clean
        and then Result.Build_UI_Clean
        and then Result.Search_Clean
        and then Result.Quick_Open_Clean
        and then Result.File_Tree_Clean;
      return Result;
   end Audit_Product_Surface_No_Demo_State;

   function Assert_Product_Surface_No_Demo_State_Coherent
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Audit_Product_Surface_No_Demo_State (S).Coherent;
   end Assert_Product_Surface_No_Demo_State_Coherent;

end Editor.Product_Surface_Cleanup;
