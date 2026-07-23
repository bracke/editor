with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Feature_Diagnostics.Display;
with Editor.Feature_Diagnostics.Filtering;
with Editor.Feature_Diagnostics.Item_Accessors;
with Editor.Feature_Diagnostics.Item_Queries;
with Editor.Feature_Diagnostics.Selection;

package body Editor.Feature_Diagnostics.Maintenance is

   use type Editor.Feature_Panel.Feature_Id;

   package Item_Accessors_Pkg renames Editor.Feature_Diagnostics.Item_Accessors;
   package Selection_Pkg renames Editor.Feature_Diagnostics.Selection;

   function Row_Count
     (Diagnostics : Diagnostics_Feature_State) return Natural
      renames Item_Accessors_Pkg.Row_Count;

   function Item_At
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Diagnostic_Item
      renames Editor.Feature_Diagnostics.Item_Queries.Item_At;

   function Contains_Case_Insensitive
     (Haystack : String;
      Needle   : String) return Boolean
   is
      Normal_Haystack : constant String :=
        Editor.Feature_Diagnostics.Display.Normalize_Diagnostics_Filter_Text (Haystack);
      Normal_Needle : constant String :=
        Editor.Feature_Diagnostics.Display.Normalize_Diagnostics_Filter_Text (Needle);
   begin
      return Normal_Needle'Length = 0
        or else Ada.Strings.Fixed.Index (Normal_Haystack, Normal_Needle) /= 0;
   end Contains_Case_Insensitive;

   function Diagnostic_Matches_Source_Label_Filter
     (Diagnostics : Diagnostics_Feature_State;
      Item        : Diagnostic_Item) return Boolean
   is
      Needle : constant String := To_String (Diagnostics.Filter.Source_Text);
   begin
      if Needle'Length = 0 then
         return True;
      end if;

      return Contains_Case_Insensitive
        (Editor.Feature_Diagnostics.Display.Source_Filter_Label_For (Item), Needle);
   end Diagnostic_Matches_Source_Label_Filter;

   function Build_Diagnostic_Count
     (Diagnostics : Diagnostics_Feature_State) return Natural
      renames Editor.Feature_Diagnostics.Filtering.Build_Diagnostic_Count;

   procedure Refresh_Filter_Active
     (Diagnostics : in out Diagnostics_Feature_State)
      renames Editor.Feature_Diagnostics.Display.Refresh_Filter_Active;

   function Is_Build_Produced_Item (Item : Diagnostic_Item) return Boolean
      renames Editor.Feature_Diagnostics.Display.Is_Build_Produced_Item;

   function Map_Diagnostic_Row_To_Item
     (Diagnostics                    : Diagnostics_Feature_State;
      Panel                          : Editor.Feature_Panel.Feature_Panel_State;
      Row                            : Natural;
      Expected_Projection_Generation : Natural := 0) return Natural
   is
      Id_Value : Natural := 0;
   begin
      if Editor.Feature_Panel.Active_Feature (Panel) /= Editor.Feature_Panel.Diagnostics_Feature
        or else not Editor.Feature_Panel.Projection_Generation_Matches
          (Panel, Expected_Projection_Generation)
        or else not Editor.Feature_Panel.Projection_Row_Index_Is_Valid (Panel, Row)
        or else not Editor.Feature_Panel.Row_Is_Selectable (Panel, Positive (Row))
      then
         return 0;
      end if;
      Id_Value := Editor.Feature_Panel.Row_Source_Index (Panel, Positive (Row));
      if Id_Value = 0 then
         return 0;
      end if;
      return Selection_Pkg.Index_For_Id (Diagnostics, Diagnostic_Id (Id_Value));
   end Map_Diagnostic_Row_To_Item;

   function Validate_Diagnostic_Target
     (Diagnostics         : Diagnostics_Feature_State;
      Index               : Positive;
      Active_Buffer_Token : Natural) return Boolean
   is
      Item : constant Diagnostic_Item := Item_At (Diagnostics, Index);
   begin
      return Item.Id /= No_Diagnostic
        and then Item.Has_Target
        and then Active_Buffer_Token /= No_Buffer
        and then Item.Target_Buffer = Active_Buffer_Token
        and then Item.Target_Line > 0;
   end Validate_Diagnostic_Target;

   function Validate_Diagnostic_Id_Target
     (Diagnostics         : Diagnostics_Feature_State;
      Id                  : Diagnostic_Id;
      Active_Buffer_Token : Natural) return Boolean
   is
      Index : constant Natural := Selection_Pkg.Map_Diagnostic_Id_To_Item (Diagnostics, Id);
   begin
      return Index /= 0
        and then Validate_Diagnostic_Target
          (Diagnostics, Positive (Index), Active_Buffer_Token);
   end Validate_Diagnostic_Id_Target;

   function Validate_Row_Action
     (Diagnostics                    : Diagnostics_Feature_State;
      Panel                          : Editor.Feature_Panel.Feature_Panel_State;
      Row                            : Natural;
      Expected_Projection_Generation : Natural := 0) return Boolean
   is
   begin
      return Map_Diagnostic_Row_To_Item
        (Diagnostics, Panel, Row, Expected_Projection_Generation) /= 0;
   end Validate_Row_Action;

   procedure Reset_Exhausted_Projection_Predicates
     (Diagnostics : in out Diagnostics_Feature_State)
   is
      Source_Matches : Natural := 0;
   begin
      if Diagnostics.Filter.Build_Only and then Build_Diagnostic_Count (Diagnostics) = 0 then
         Diagnostics.Filter.Build_Only := False;
      end if;

      if Length (Diagnostics.Filter.Source_Text) > 0 then
         for I in 1 .. Row_Count (Diagnostics) loop
            if Diagnostic_Matches_Source_Label_Filter
              (Diagnostics, Diagnostics.Rows.Element (I - 1))
            then
               Source_Matches := Source_Matches + 1;
            end if;
         end loop;

         if Source_Matches = 0 then
            Diagnostics.Filter.Source_Text := Null_Unbounded_String;
         end if;
      end if;

      Refresh_Filter_Active (Diagnostics);
   end Reset_Exhausted_Projection_Predicates;

   procedure Reset_Diagnostics_For_Buffer_Close
     (Diagnostics : in out Diagnostics_Feature_State;
      Buffer_Token : Natural)
   is
      I : Diagnostic_Row_Vectors.Extended_Index := Diagnostics.Rows.First_Index;
   begin
      if Diagnostics.Rows.Is_Empty or else Buffer_Token = No_Buffer then
         return;
      end if;
      while I <= Diagnostics.Rows.Last_Index loop
         if Diagnostics.Rows.Element (I).Target_Buffer = Buffer_Token
         then
            Diagnostics.Rows.Delete (I);
         else
            I := I + 1;
         end if;
      end loop;
      Reset_Exhausted_Projection_Predicates (Diagnostics);
   end Reset_Diagnostics_For_Buffer_Close;

   procedure Reset_Diagnostics_For_Project_Close
     (Diagnostics : in out Diagnostics_Feature_State)
   is
   begin
      Clear_Diagnostics (Diagnostics);
      Show_All (Diagnostics);
   end Reset_Diagnostics_For_Project_Close;

   procedure Reset_Diagnostics_For_Workspace_Close
     (Diagnostics : in out Diagnostics_Feature_State)
   is
   begin
      Clear_Diagnostics (Diagnostics);
      Show_All (Diagnostics);
      Diagnostics.Next_Id := 1;
   end Reset_Diagnostics_For_Workspace_Close;

   procedure Mark_Diagnostics_For_Buffer_Stale
     (Diagnostics  : in out Diagnostics_Feature_State;
      Buffer_Token : Natural)
   is
   begin
      if Buffer_Token = No_Buffer then
         return;
      end if;

      for I in 1 .. Row_Count (Diagnostics) loop
         declare
            Item : Diagnostic_Item := Diagnostics.Rows.Element (I - 1);
         begin
            if Item.Target_Buffer = Buffer_Token then
               Item.Is_Stale := True;
               Diagnostics.Rows.Replace_Element (I - 1, Item);
            end if;
         end;
      end loop;
   end Mark_Diagnostics_For_Buffer_Stale;

   function Normalized_Diagnostic_Path (Path : String) return String
   is
      Result : String (Path'Range);
      Last   : Integer := Path'Last;
   begin
      if Path'Length = 0 then
         return "";
      end if;

      while Last > Path'First
        and then (Path (Last) = '/' or else Path (Last) = Character'Val (16#5C#))
      loop
         Last := Last - 1;
      end loop;

      for I in Path'First .. Last loop
         if Path (I) = Character'Val (16#5C#) then
            Result (I) := '/';
         else
            Result (I) := Path (I);
         end if;
      end loop;

      return Result (Path'First .. Last);
   end Normalized_Diagnostic_Path;

   function Same_Or_Descendant_Diagnostic_Path
     (Path : String;
      Root : String) return Boolean
   is
      P : constant String := Normalized_Diagnostic_Path (Path);
      R : constant String := Normalized_Diagnostic_Path (Root);
   begin
      if P'Length = 0 or else R'Length = 0 then
         return False;
      elsif P = R then
         return True;
      elsif P'Length > R'Length
        and then P (P'First .. P'First + R'Length - 1) = R
        and then P (P'First + R'Length) = '/'
      then
         return True;
      else
         return False;
      end if;
   end Same_Or_Descendant_Diagnostic_Path;

   procedure Mark_Diagnostics_For_Source_Path_Stale
     (Diagnostics : in out Diagnostics_Feature_State;
      Old_Path    : String;
      New_Path    : String := "")
   is
   begin
      if Old_Path'Length = 0 and then New_Path'Length = 0 then
         return;
      end if;

      for I in 1 .. Row_Count (Diagnostics) loop
         declare
            Item   : Diagnostic_Item := Diagnostics.Rows.Element (I - 1);
            Source : constant String := To_String (Item.Source_Label);
         begin
            if Same_Or_Descendant_Diagnostic_Path (Source, Old_Path)
              or else Same_Or_Descendant_Diagnostic_Path (Source, New_Path)
            then
               Item.Is_Stale := True;
               Diagnostics.Rows.Replace_Element (I - 1, Item);
            end if;
         end;
      end loop;
   end Mark_Diagnostics_For_Source_Path_Stale;

   function Clear_Build_Diagnostics
     (Diagnostics : in out Diagnostics_Feature_State) return Natural
   is
      Removed : Natural := 0;
      I       : Diagnostic_Row_Vectors.Extended_Index := Diagnostics.Rows.First_Index;
   begin
      while I <= Diagnostics.Rows.Last_Index loop
         if Is_Build_Produced_Item (Diagnostics.Rows.Element (I)) then
            Diagnostics.Rows.Delete (I);
            Removed := Removed + 1;
         else
            I := I + 1;
         end if;
      end loop;

      Reset_Exhausted_Projection_Predicates (Diagnostics);
      return Removed;
   end Clear_Build_Diagnostics;

   procedure Reconcile_Diagnostics_After_Filter_Change
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : in out Editor.Feature_Panel.Feature_Panel_State)
   is
   begin
      if Editor.Feature_Panel.Active_Feature (Panel) = Editor.Feature_Panel.Diagnostics_Feature then
         Project_Rows (Diagnostics, Panel);
      end if;
   end Reconcile_Diagnostics_After_Filter_Change;

end Editor.Feature_Diagnostics.Maintenance;
