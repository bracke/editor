with Ada.Characters.Handling;
with Ada.Containers;
with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;
with GNAT.OS_Lib;
with Editor.Workspace_Persistence.Text_Format; use Editor.Workspace_Persistence.Text_Format;
with Editor.Workspace_Persistence.Path_Validation; use Editor.Workspace_Persistence.Path_Validation;
with Editor.Workspace_Persistence.Snapshot_Model; use Editor.Workspace_Persistence.Snapshot_Model;
with Editor.Workspace_Persistence.File_IO; use Editor.Workspace_Persistence.File_IO;
with Editor.Workspace_Persistence.Audits; use Editor.Workspace_Persistence.Audits;

package body Editor.Workspace_Persistence.Parsing is

   use type Ada.Containers.Count_Type;
   use type Ada.Directories.File_Kind;

   function Has_Malformed_Metadata_Separators
     (Line      : String;
      First_Sep : Natural) return Boolean
   is
   begin
      if First_Sep = 0
        or else First_Sep = Line'Last
        or else Line (Line'Last) = '|'
      then
         return True;
      end if;

      for I in First_Sep .. Line'Last - 1 loop
         if Line (I) = '|' and then Line (I + 1) = '|' then
            return True;
         end if;
      end loop;

      return False;
   end Has_Malformed_Metadata_Separators;

   procedure Report_Unsupported_Field
     (Snapshot : in out Workspace_Snapshot;
      Status   : in out Workspace_Persistence_Status;
      Line_No  : Natural;
      Text     : String)
   is
   begin
      Add_Diagnostic (Snapshot, Unsupported_Key, Line_No, Text);
      Mark_Partial (Status);
   end Report_Unsupported_Field;

   procedure Parse_Project_Reference_Line
     (Line     : String;
      Line_No  : Natural;
      Snapshot : in out Workspace_Snapshot;
      Status   : in out Workspace_Persistence_Status)
   is
      Found : Boolean;
      Val   : constant String := Value_After_Strict (Line, "project-root", Found);
   begin
      if Found then
         if Val'Length = 0 or else Val /= Trim (Val) then
            Add_Diagnostic (Snapshot, Invalid_Path, Line_No, Line);
            Mark_Partial (Status);
            return;
         end if;

         Set_Project_Root (Snapshot, Val);
         if not Snapshot.Has_Root then
            Add_Diagnostic (Snapshot, Invalid_Path, Line_No, Line);
            Mark_Partial (Status);
         end if;
      else
         Add_Diagnostic (Snapshot, Unsupported_Key, Line_No, Line);
         Mark_Partial (Status);
      end if;
   end Parse_Project_Reference_Line;


   procedure Parse_Open_File_Line
     (Line     : String;
      Line_No  : Natural;
      Snapshot : in out Workspace_Snapshot;
      Status   : in out Workspace_Persistence_Status)
   is
      Sep   : constant Natural := Ada.Strings.Fixed.Index (Line, "|");
      Item : Workspace_File_Entry;
      Pos   : Natural;
      Next  : Natural;
      Field : Unbounded_String;
      Found : Boolean;
      N     : Natural;
      B     : Boolean;
      Saw_Relative : Boolean := False;
      Saw_Row      : Boolean := False;
      Saw_Col      : Boolean := False;
      Saw_View     : Boolean := False;
      Saw_Unsupported_Field : Boolean := False;
      Saw_Duplicate_Field   : Boolean := False;
      Field_No              : Natural := 0;
   begin
      if Sep = 0 then
         --  The current workspace schema writes open-file rows with explicit
         --  structural metadata.  A bare path is noncanonical and is rejected
         --  instead of being treated as structural input.
         if Ada.Strings.Fixed.Index (Line, "=") > 0 then
            Add_Diagnostic (Snapshot, Unsupported_Key, Line_No, Line);
         else
            Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
         end if;
         Mark_Partial (Status);
         return;
      elsif Has_Malformed_Metadata_Separators (Line, Sep) then
         Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
         Mark_Partial (Status);
         return;
      end if;

      declare
         Raw_Path_Original : constant String := Line (Line'First .. Sep - 1);
         Raw_Path          : constant String := Trim (Raw_Path_Original);
      begin
         if Raw_Path_Original /= Raw_Path then
            Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
            Mark_Partial (Status);
            return;
         elsif Ada.Strings.Fixed.Index (Raw_Path, "=") > 0 then
            Add_Diagnostic (Snapshot, Unsupported_Key, Line_No, Raw_Path);
            Mark_Partial (Status);
            return;
         end if;
         Item.Path := To_Unbounded_String (Raw_Path);
      end;

      if Length (Item.Path) = 0 then
         Add_Diagnostic (Snapshot, Invalid_Path, Line_No, Line);
         Mark_Partial (Status);
         return;
      end if;

      Pos := Sep + 1;
      while Pos <= Line'Last loop
         Next := Ada.Strings.Fixed.Index (Line (Pos .. Line'Last), "|");
         if Next = 0 then
            Field := To_Unbounded_String (Line (Pos .. Line'Last));
            Pos := Line'Last + 1;
         else
            Field := To_Unbounded_String (Line (Pos .. Next - 1));
            Pos := Next + 1;
         end if;

         Field_No := Field_No + 1;
         declare
            Text : constant String := To_String (Field);
            Val  : constant String := Value_After_Strict (Text, "row", Found);
         begin
            if Found then
               if Saw_Row or else Field_No /= 2 then
                  Saw_Duplicate_Field := True;
                  Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Text);
                  Mark_Partial (Status);
               elsif Parse_Natural_Strict (Val, N) then
                  Item.Cursor_Row := N;
                  Saw_Row := True;
               else
                  Add_Diagnostic (Snapshot, Invalid_Number, Line_No, Text);
                  Mark_Partial (Status);
               end if;
            else
               declare
                  Val2 : constant String := Value_After_Strict (Text, "col", Found);
               begin
                  if Found then
                     if Saw_Col or else Field_No /= 3 then
                        Saw_Duplicate_Field := True;
                        Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Text);
                        Mark_Partial (Status);
                     elsif Parse_Natural_Strict (Val2, N) then
                        Item.Cursor_Column := N;
                        Saw_Col := True;
                     else
                        Add_Diagnostic (Snapshot, Invalid_Number, Line_No, Text);
                        Mark_Partial (Status);
                     end if;
                  else
                     declare
                        Val3 : constant String := Value_After_Strict (Text, "view", Found);
                     begin
                        if Found then
                           if Saw_View or else Field_No /= 4 then
                              Saw_Duplicate_Field := True;
                              Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Text);
                              Mark_Partial (Status);
                           elsif Parse_Natural_Strict (Val3, N) then
                              Item.View_First_Row := N;
                              Saw_View := True;
                           else
                              Add_Diagnostic (Snapshot, Invalid_Number, Line_No, Text);
                              Mark_Partial (Status);
                           end if;
                        else
                           declare
                              Val4 : constant String := Value_After_Strict (Text, "relative", Found);
                           begin
                              if Found then
                                 if Saw_Relative or else Field_No /= 1 then
                                    Saw_Duplicate_Field := True;
                                    Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Text);
                                    Mark_Partial (Status);
                                 elsif Parse_Boolean_Strict (Val4, B)
                                   and then B
                                 then
                                    Item.Is_Project_Relative := True;
                                    Saw_Relative := True;
                                 else
                                    --  The current canonical workspace schema
                                    --  only persists project-relative file
                                    --  references.  relative=false is not a
                                    --  retained structural variant.
                                    Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Text);
                                    Mark_Partial (Status);
                                 end if;
                              else
                                 --  Open-file entries may only carry the
                                 --  canonical structural metadata keys.
                                 Saw_Unsupported_Field := True;
                                 Report_Unsupported_Field
                                   (Snapshot, Status, Line_No, Text);
                              end if;
                           end;
                        end if;
                     end;
                  end if;
               end;
            end if;
         end;
      end loop;

      if Saw_Unsupported_Field or else Saw_Duplicate_Field then
         Mark_Partial (Status);
         return;
      end if;

      if not (Saw_Relative and Saw_Row and Saw_Col and Saw_View) then
         Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
         Mark_Partial (Status);
         return;
      end if;

      declare
         Before : constant Natural := Open_File_Count (Snapshot);
      begin
         Add_Open_File (Snapshot, Item);
         if Open_File_Count (Snapshot) = Before then
            if Item.Is_Project_Relative
              and then Is_Safe_Project_Relative_Path (To_String (Item.Path))
            then
               Add_Diagnostic (Snapshot, Duplicate_Path, Line_No, To_String (Item.Path));
            else
               Add_Diagnostic (Snapshot, Invalid_Path, Line_No, To_String (Item.Path));
            end if;
            Mark_Partial (Status);
         end if;
      end;
   exception
      when others =>
         Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
         Mark_Partial (Status);
   end Parse_Open_File_Line;

   procedure Load_From_File
     (Path     : String;
      Snapshot : out Workspace_Snapshot;
      Status   : out Workspace_Persistence_Status)
   is
      File    : Ada.Text_IO.File_Type;
      Line_No : Natural := 0;
      Section : Section_Id := Root_Section;
      Header  : Boolean := False;
      Partial : Workspace_Persistence_Status := Workspace_Persistence_Ok;
      Project_Root_Seen    : Boolean := False;
      Project_Root_Row_Seen : Boolean := False;
      Last_Section_Rank    : Natural := 0;
      Open_Section_Seen    : Boolean := False;
      Active_Section_Seen  : Boolean := False;
      Active_File_Row_Seen : Boolean := False;
      Expanded_Section_Seen : Boolean := False;
      Panels_Seen          : Boolean := False;
      Continuity_Seen      : Boolean := False;
      Panel_File_Tree_Seen : Boolean := False;
      Panel_Width_Seen     : Boolean := False;
      Panel_Bottom_Seen    : Boolean := False;
      Panel_Height_Seen    : Boolean := False;
      Panel_Content_Seen   : Boolean := False;
      Panel_Invalid        : Boolean := False;
      Panel_Field_No       : Natural := 0;
      Panel_File_Tree_Visible_Value : Boolean := True;
      Panel_File_Tree_Width_Value   : Natural := Default_File_Tree_Width;
      Panel_Bottom_Visible_Value    : Boolean := False;
      Panel_Bottom_Height_Value     : Natural := Default_Bottom_Height;
      Panel_Bottom_Content_Value    : Bottom_Content_Id := Workspace_Problems_Content;
      Continuity_Recent_Seen        : Boolean := False;
      Continuity_Quick_Open_Seen    : Boolean := False;
      Continuity_Quick_Filter_Seen  : Boolean := False;
      Continuity_Feature_Visible_Seen : Boolean := False;
      Continuity_Active_Feature_Seen  : Boolean := False;
      Continuity_Invalid            : Boolean := False;
      Continuity_Field_No           : Natural := 0;
      Continuity_Has_Recent_Value   : Boolean := False;
      Continuity_Recent_Value       : Unbounded_String := Null_Unbounded_String;
      Continuity_Quick_Open_Value   : Unbounded_String := Null_Unbounded_String;
      Continuity_Quick_Filter_Value : Workspace_Quick_Open_File_Kind_Filter :=
        Workspace_Quick_Open_All_Files;
      Continuity_Feature_Visible_Value : Boolean := False;
      Continuity_Active_Feature_Value  : Workspace_Feature_Panel_Id :=
        Workspace_Outline_Feature;
      Last_Expanded_Path            : Unbounded_String := Null_Unbounded_String;
   begin
      Clear (Snapshot);
      Status := Workspace_Persistence_Ok;

      if not Ada.Directories.Exists (Path) then
         Status := Workspace_Persistence_Not_Found;
         return;
      end if;

      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         declare
            Raw_Line : constant String := Ada.Text_IO.Get_Line (File);
            Line     : constant String := Trim (Raw_Line);
         begin
            Line_No := Line_No + 1;
            if Line'Length = 0 then
               --  Canonical workspace save emits no blank rows.  Before the
               --  version header, any row is a format error because the header
               --  must be the first physical line of the strict schema.
               Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Raw_Line);
               if not Header then
                  Ada.Text_IO.Close (File);
                  Status := Workspace_Persistence_Invalid_Format;
                  return;
               end if;
               Mark_Partial (Partial);
            elsif Raw_Line /= Line then
               --  The current workspace schema is emitted in a canonical
               --  whitespace-free text form.  Do not trim padded rows into
               --  valid structural state; before the header this invalidates
               --  the whole file rather than allowing later repair.
               Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Raw_Line);
               if not Header then
                  Ada.Text_IO.Close (File);
                  Status := Workspace_Persistence_Invalid_Format;
                  return;
               end if;
               Mark_Partial (Partial);
            elsif Line (Line'First) = '[' and then Line (Line'Last) = ']' then
               if not Header then
                  Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                  Ada.Text_IO.Close (File);
                  Status := Workspace_Persistence_Invalid_Format;
                  return;
               end if;
               declare
                  Name      : constant String := Line (Line'First + 1 .. Line'Last - 1);
                  Rank      : Natural := 0;
                  Duplicate : Boolean := False;
                  Target    : Section_Id := Unknown_Section;
               begin
                  if Name = "open-files" then
                     Rank := 1;
                     Duplicate := Open_Section_Seen;
                     Target := Open_Files_Section;
                  elsif Name = "active-file" then
                     Rank := 2;
                     Duplicate := Active_Section_Seen;
                     Target := Active_File_Section;
                  elsif Name = "file-tree-expanded" then
                     Rank := 3;
                     Duplicate := Expanded_Section_Seen;
                     Target := File_Tree_Expanded_Section;
                  elsif Name = "panels" then
                     Rank := 4;
                     Duplicate := Panels_Seen;
                     Target := Panels_Section;
                  elsif Name = "continuity" then
                     Rank := 5;
                     Duplicate := Continuity_Seen;
                     Target := Continuity_Section;
                  else
                     Section := Unknown_Section;
                     Add_Diagnostic (Snapshot, Unknown_Section, Line_No, Name);
                     Mark_Partial (Partial);
                  end if;

                  if Rank > 0 then
                     if Duplicate or else Rank <= Last_Section_Rank then
                        Section := Unknown_Section;
                        Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                        Mark_Partial (Partial);
                     else
                        Section := Target;
                        Last_Section_Rank := Rank;
                        case Target is
                           when Open_Files_Section =>
                              Open_Section_Seen := True;
                           when Active_File_Section =>
                              Active_Section_Seen := True;
                           when File_Tree_Expanded_Section =>
                              Expanded_Section_Seen := True;
                           when Panels_Section =>
                              Panels_Seen := True;
                           when Continuity_Section =>
                              Continuity_Seen := True;
                           when others =>
                              null;
                        end case;
                     end if;
                  end if;
               end;
            elsif not Header then
               declare
                  Prefix : constant String := "editor-workspace-version=";
                  N      : Natural;
               begin
                  if Line'Length < Prefix'Length
                    or else Line (Line'First .. Line'First + Prefix'Length - 1) /= Prefix
                  then
                     Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                     Ada.Text_IO.Close (File);
                     Status := Workspace_Persistence_Invalid_Format;
                     return;
                  end if;
                  if not Parse_Natural_Strict (Line (Line'First + Prefix'Length .. Line'Last), N) then
                     Add_Diagnostic (Snapshot, Invalid_Number, Line_No, Line);
                     Ada.Text_IO.Close (File);
                     Status := Workspace_Persistence_Invalid_Format;
                     return;
                  elsif N /= Current_Format_Version then
                     Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                     Ada.Text_IO.Close (File);
                     Status := Workspace_Persistence_Unsupported_Version;
                     return;
                  end if;
                  Snapshot.Format_Version := N;
                  Header := True;
               end;
            else
               case Section is
                  when Root_Section =>
                     declare
                        Found : Boolean;
                        Val   : constant String := Value_After_Strict
                          (Line, "project-root", Found);
                        pragma Unreferenced (Val);
                     begin
                        if Project_Root_Row_Seen then
                           --  The strict canonical root area allows at most
                           --  one structural row.  A malformed/unsupported
                           --  first root row consumes the slot; a later
                           --  project-root row must not repair it.
                           Add_Diagnostic
                             (Snapshot, Malformed_Line, Line_No, Line);
                           Mark_Partial (Partial);
                        else
                           Project_Root_Row_Seen := True;
                           Parse_Project_Reference_Line
                             (Line, Line_No, Snapshot, Partial);
                           if Found and then Snapshot.Has_Root then
                              Project_Root_Seen := True;
                           end if;
                        end if;
                     end;
                  when Open_Files_Section =>
                     Parse_Open_File_Line (Line, Line_No, Snapshot, Partial);
                  when Active_File_Section =>
                     if Active_File_Row_Seen then
                        Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                        Mark_Partial (Partial);
                     else
                        Active_File_Row_Seen := True;
                        declare
                           Sep : constant Natural := Ada.Strings.Fixed.Index (Line, "|");
                           Rel : Boolean := True;
                        Saw_Relative : Boolean := False;
                        Saw_Unsupported_Field : Boolean := False;
                        Saw_Duplicate_Field : Boolean := False;
                        Field_No : Natural := 0;

                        procedure Apply_Active_Path (Raw_Path : String) is
                           Candidate : constant String := Trim (Raw_Path);
                        begin
                           if Raw_Path /= Candidate then
                              Add_Diagnostic
                                (Snapshot, Malformed_Line, Line_No, Raw_Path);
                              Mark_Partial (Partial);
                              return;
                           end if;

                           Set_Active_File_Path (Snapshot, Candidate, Rel);
                           if not Snapshot.Has_Active then
                              Add_Diagnostic
                                (Snapshot, Invalid_Path, Line_No, Raw_Path);
                              Mark_Partial (Partial);
                           end if;
                        end Apply_Active_Path;
                     begin
                        if Sep = 0 then
                           --  The current workspace schema writes active-file
                           --  rows with explicit relative metadata.  Do not
                           --  accept path-only noncanonical rows here.
                           if Ada.Strings.Fixed.Index (Line, "=") > 0 then
                              Add_Diagnostic (Snapshot, Unsupported_Key, Line_No, Line);
                           else
                              Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                           end if;
                           Mark_Partial (Partial);
                        elsif Has_Malformed_Metadata_Separators (Line, Sep) then
                           Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                           Mark_Partial (Partial);
                        else
                           declare
                              Pos   : Natural := Sep + 1;
                              Next  : Natural;
                              Field : Unbounded_String;
                              Found : Boolean;
                              B     : Boolean;
                           begin
                              while Pos <= Line'Last loop
                                 Next := Ada.Strings.Fixed.Index (Line (Pos .. Line'Last), "|");
                                 if Next = 0 then
                                    Field := To_Unbounded_String (Line (Pos .. Line'Last));
                                    Pos := Line'Last + 1;
                                 else
                                    Field := To_Unbounded_String (Line (Pos .. Next - 1));
                                    Pos := Next + 1;
                                 end if;

                                 Field_No := Field_No + 1;
                                 declare
                                    Text : constant String := To_String (Field);
                                    Val  : constant String := Value_After_Strict (Text, "relative", Found);
                                 begin
                                    if Found then
                                       if Saw_Relative or else Field_No /= 1 then
                                          Saw_Duplicate_Field := True;
                                          Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Text);
                                          Mark_Partial (Partial);
                                       elsif Parse_Boolean_Strict (Val, B)
                                         and then B
                                       then
                                          Rel := True;
                                          Saw_Relative := True;
                                       else
                                          --  Active-file restore is restricted
                                          --  to the same project-relative
                                          --  canonical path form used for
                                          --  open-file rows.
                                          Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Text);
                                          Mark_Partial (Partial);
                                       end if;
                                    else
                                       --  Active-file state may only carry the
                                       --  structural relative flag.
                                       Saw_Unsupported_Field := True;
                                       Report_Unsupported_Field
                                         (Snapshot, Partial, Line_No, Text);
                                    end if;
                                 end;
                              end loop;
                           end;
                           if Saw_Relative
                             and then not Saw_Unsupported_Field
                             and then not Saw_Duplicate_Field
                           then
                              Apply_Active_Path (Line (Line'First .. Sep - 1));
                           else
                              Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                              Mark_Partial (Partial);
                           end if;
                        end if;
                        exception
                           when others =>
                              Mark_Partial (Partial);
                        end;
                     end if;
                  when File_Tree_Expanded_Section =>
                     declare
                        Before : constant Natural := Expanded_File_Tree_Path_Count (Snapshot);
                        Valid  : Boolean := False;
                        Clean  : constant String := Normalize_Project_Relative_Path
                          (Line, Valid);
                     begin
                        if Ada.Strings.Fixed.Index (Line, "=") > 0 then
                           Add_Diagnostic (Snapshot, Unsupported_Key, Line_No, Line);
                           Mark_Partial (Partial);
                        elsif not Valid then
                           Add_Diagnostic (Snapshot, Invalid_Path, Line_No, Line);
                           Mark_Partial (Partial);
                        elsif Length (Last_Expanded_Path) > 0
                          and then Clean <= To_String (Last_Expanded_Path)
                        then
                           --  Save normalizes expanded directory paths into
                           --  deterministic ascending order.  Reject equal or
                           --  descending rows so load does not accept another
                           --  canonical spelling after current-name resolution
                           --  have been removed.
                           if Clean = To_String (Last_Expanded_Path) then
                              Add_Diagnostic
                                (Snapshot, Duplicate_Path, Line_No, Line);
                           else
                              Add_Diagnostic
                                (Snapshot, Malformed_Line, Line_No, Line);
                           end if;
                           Mark_Partial (Partial);
                        else
                           Add_Expanded_File_Tree_Path (Snapshot, Clean);
                           if Expanded_File_Tree_Path_Count (Snapshot) = Before then
                              Add_Diagnostic
                                (Snapshot, Duplicate_Path, Line_No, Line);
                              Mark_Partial (Partial);
                           else
                              Last_Expanded_Path := To_Unbounded_String (Clean);
                           end if;
                        end if;
                     end;
                  when Panels_Section =>
                     declare
                        Eq : constant Natural := Ada.Strings.Fixed.Index (Line, "=");
                        B  : Boolean;
                        N  : Natural;
                        C  : Bottom_Content_Id;
                     begin
                        Panel_Field_No := Panel_Field_No + 1;
                        if Eq = 0 then
                           Panel_Invalid := True;
                           Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                           Mark_Partial (Partial);
                        else
                           declare
                              Key : constant String := Line (Line'First .. Eq - 1);
                              Val : constant String := Line (Eq + 1 .. Line'Last);
                           begin
                              if Key = "file-tree-visible" then
                                 if Panel_File_Tree_Seen or else Panel_Field_No /= 1 then
                                    Panel_Invalid := True;
                                    Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                                    Mark_Partial (Partial);
                                 elsif Parse_Boolean_Strict (Val, B) then
                                    Panel_File_Tree_Visible_Value := B;
                                    Panel_File_Tree_Seen := True;
                                 else
                                    Panel_Invalid := True;
                                    Add_Diagnostic (Snapshot, Invalid_Panel_Value, Line_No, Line);
                                    Mark_Partial (Partial);
                                 end if;
                              elsif Key = "file-tree-width" then
                                 if Panel_Width_Seen or else Panel_Field_No /= 2 then
                                    Panel_Invalid := True;
                                    Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                                    Mark_Partial (Partial);
                                 elsif Parse_Natural_Strict (Val, N) then
                                    if N = 0 then
                                       Panel_Invalid := True;
                                       Add_Diagnostic (Snapshot, Invalid_Panel_Value, Line_No, Line);
                                       Mark_Partial (Partial);
                                    else
                                       Panel_File_Tree_Width_Value := N;
                                       Panel_Width_Seen := True;
                                    end if;
                                 else
                                    Panel_Invalid := True;
                                    Add_Diagnostic (Snapshot, Invalid_Number, Line_No, Line);
                                    Mark_Partial (Partial);
                                 end if;
                              elsif Key = "bottom-visible" then
                                 if Panel_Bottom_Seen or else Panel_Field_No /= 3 then
                                    Panel_Invalid := True;
                                    Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                                    Mark_Partial (Partial);
                                 elsif Parse_Boolean_Strict (Val, B) then
                                    Panel_Bottom_Visible_Value := B;
                                    Panel_Bottom_Seen := True;
                                 else
                                    Panel_Invalid := True;
                                    Add_Diagnostic (Snapshot, Invalid_Panel_Value, Line_No, Line);
                                    Mark_Partial (Partial);
                                 end if;
                              elsif Key = "bottom-height" then
                                 if Panel_Height_Seen or else Panel_Field_No /= 4 then
                                    Panel_Invalid := True;
                                    Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                                    Mark_Partial (Partial);
                                 elsif Parse_Natural_Strict (Val, N) then
                                    if N = 0 then
                                       Panel_Invalid := True;
                                       Add_Diagnostic (Snapshot, Invalid_Panel_Value, Line_No, Line);
                                       Mark_Partial (Partial);
                                    else
                                       Panel_Bottom_Height_Value := N;
                                       Panel_Height_Seen := True;
                                    end if;
                                 else
                                    Panel_Invalid := True;
                                    Add_Diagnostic (Snapshot, Invalid_Number, Line_No, Line);
                                    Mark_Partial (Partial);
                                 end if;
                              elsif Key = "bottom-content" then
                                 if Panel_Content_Seen or else Panel_Field_No /= 5 then
                                    Panel_Invalid := True;
                                    Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                                    Mark_Partial (Partial);
                                 elsif Parse_Content_Strict (Val, C) then
                                    Panel_Bottom_Content_Value := C;
                                    Panel_Content_Seen := True;
                                 else
                                    Panel_Invalid := True;
                                    Add_Diagnostic (Snapshot, Invalid_Panel_Value, Line_No, Line);
                                    Mark_Partial (Partial);
                                 end if;
                              else
                                 Panel_Invalid := True;
                                 Add_Diagnostic
                                   (Snapshot, Unsupported_Key, Line_No, Line);
                                 Mark_Partial (Partial);
                              end if;
                           end;
                        end if;
                     exception
                        when others =>
                           Panel_Invalid := True;
                           Mark_Partial (Partial);
                     end;
                  when Continuity_Section =>
                     declare
                        Eq : constant Natural := Ada.Strings.Fixed.Index (Line, "=");
                        B  : Boolean;
                        F  : Workspace_Feature_Panel_Id;
                        QF : Workspace_Quick_Open_File_Kind_Filter;
                        Valid : Boolean := False;
                     begin
                        Continuity_Field_No := Continuity_Field_No + 1;
                        if Eq = 0 then
                           Continuity_Invalid := True;
                           Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                           Mark_Partial (Partial);
                        else
                           declare
                              Key : constant String := Line (Line'First .. Eq - 1);
                              Val : constant String := Line (Eq + 1 .. Line'Last);
                           begin
                              if Key = "recent-project" then
                                 if Continuity_Recent_Seen or else Continuity_Field_No /= 1 then
                                    Continuity_Invalid := True;
                                    Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                                    Mark_Partial (Partial);
                                 elsif Val'Length = 0 then
                                    Continuity_Has_Recent_Value := False;
                                    Continuity_Recent_Value := Null_Unbounded_String;
                                    Continuity_Recent_Seen := True;
                                 elsif Val = Trim (Val)
                                   and then not Has_Control_Character (Val)
                                 then
                                    Continuity_Has_Recent_Value := True;
                                    Continuity_Recent_Value := To_Unbounded_String (Val);
                                    Continuity_Recent_Seen := True;
                                 else
                                    Continuity_Invalid := True;
                                    Add_Diagnostic (Snapshot, Invalid_Path, Line_No, Line);
                                    Mark_Partial (Partial);
                                 end if;
                              elsif Key = "quick-open-scope" then
                                 if Continuity_Quick_Open_Seen or else Continuity_Field_No /= 2 then
                                    Continuity_Invalid := True;
                                    Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                                    Mark_Partial (Partial);
                                 else
                                    declare
                                       Scope : constant String :=
                                         Normalize_Directory_Scope (Val, Valid);
                                    begin
                                       if Valid then
                                          Continuity_Quick_Open_Value :=
                                            To_Unbounded_String (Scope);
                                          Continuity_Quick_Open_Seen := True;
                                       else
                                          Continuity_Invalid := True;
                                          Add_Diagnostic (Snapshot, Invalid_Path, Line_No, Line);
                                          Mark_Partial (Partial);
                                       end if;
                                    end;
                                 end if;
                              elsif Key = "quick-open-filter" then
                                 if Continuity_Quick_Filter_Seen
                                   or else Continuity_Field_No /= 3
                                 then
                                    Continuity_Invalid := True;
                                    Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                                    Mark_Partial (Partial);
                                 elsif Parse_Quick_Open_Filter_Strict (Val, QF) then
                                    Continuity_Quick_Filter_Value := QF;
                                    Continuity_Quick_Filter_Seen := True;
                                 else
                                    Continuity_Invalid := True;
                                    Add_Diagnostic (Snapshot, Invalid_Panel_Value, Line_No, Line);
                                    Mark_Partial (Partial);
                                 end if;
                              elsif Key = "feature-panel-visible" then
                                 if Continuity_Feature_Visible_Seen
                                   or else Continuity_Field_No /= 4
                                 then
                                    Continuity_Invalid := True;
                                    Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                                    Mark_Partial (Partial);
                                 elsif Parse_Boolean_Strict (Val, B) then
                                    Continuity_Feature_Visible_Value := B;
                                    Continuity_Feature_Visible_Seen := True;
                                 else
                                    Continuity_Invalid := True;
                                    Add_Diagnostic (Snapshot, Invalid_Panel_Value, Line_No, Line);
                                    Mark_Partial (Partial);
                                 end if;
                              elsif Key = "active-feature-panel" then
                                 if Continuity_Active_Feature_Seen
                                   or else Continuity_Field_No /= 5
                                 then
                                    Continuity_Invalid := True;
                                    Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                                    Mark_Partial (Partial);
                                 elsif Parse_Feature_Panel_Strict (Val, F) then
                                    Continuity_Active_Feature_Value := F;
                                    Continuity_Active_Feature_Seen := True;
                                 else
                                    Continuity_Invalid := True;
                                    Add_Diagnostic (Snapshot, Invalid_Panel_Value, Line_No, Line);
                                    Mark_Partial (Partial);
                                 end if;
                              else
                                 Continuity_Invalid := True;
                                 Add_Diagnostic
                                   (Snapshot, Unsupported_Key, Line_No, Line);
                                 Mark_Partial (Partial);
                              end if;
                           end;
                        end if;
                     exception
                        when others =>
                           Continuity_Invalid := True;
                           Mark_Partial (Partial);
                     end;
                  when Unknown_Section =>
                     Add_Diagnostic (Snapshot, Unknown_Section, Line_No, Line);
                     Mark_Partial (Partial);
               end case;
            end if;
         end;
      end loop;

      Ada.Text_IO.Close (File);

      if Header then
         if not Open_Section_Seen then
            Add_Diagnostic
              (Snapshot, Malformed_Line, 0,
               "missing canonical [open-files] section");
            Mark_Partial (Partial);
         end if;
         if not Active_Section_Seen then
            Add_Diagnostic
              (Snapshot, Malformed_Line, 0,
               "missing canonical [active-file] section");
            Mark_Partial (Partial);
         end if;
         if not Expanded_Section_Seen then
            Add_Diagnostic
              (Snapshot, Malformed_Line, 0,
               "missing canonical [file-tree-expanded] section");
            Mark_Partial (Partial);
         end if;
         if not Panels_Seen then
            Add_Diagnostic
              (Snapshot, Malformed_Line, 0,
               "missing canonical [panels] section");
            Mark_Partial (Partial);
         end if;
      end if;

      if Panels_Seen then
         if Panel_Invalid
           or else not Panel_File_Tree_Seen
           or else not Panel_Width_Seen
           or else not Panel_Bottom_Seen
           or else not Panel_Height_Seen
           or else not Panel_Content_Seen
         then
            --  Panel layout is one canonical structural record.  Do not
            --  partially restore file-tree/bottom-panel values from a
            --  malformed or incomplete [panels] section.
            Snapshot.File_Tree_Visible := True;
            Snapshot.File_Tree_Width := Default_File_Tree_Width;
            Snapshot.Bottom_Visible := False;
            Snapshot.Bottom_Height := Default_Bottom_Height;
            Snapshot.Bottom_Content := Workspace_Problems_Content;
            Add_Diagnostic
              (Snapshot, Malformed_Line, 0,
               "panels section is not in canonical order or is incomplete");
            Mark_Partial (Partial);
         else
            Snapshot.File_Tree_Visible := Panel_File_Tree_Visible_Value;
            Snapshot.File_Tree_Width := Panel_File_Tree_Width_Value;
            Snapshot.Bottom_Visible := Panel_Bottom_Visible_Value;
            Snapshot.Bottom_Height := Panel_Bottom_Height_Value;
            Snapshot.Bottom_Content := Panel_Bottom_Content_Value;
         end if;
      end if;

      if Continuity_Seen then
         if Continuity_Invalid
           or else not Continuity_Recent_Seen
           or else not Continuity_Quick_Open_Seen
           or else not Continuity_Quick_Filter_Seen
           or else not Continuity_Feature_Visible_Seen
           or else not Continuity_Active_Feature_Seen
         then
            Snapshot.Has_Recent_Project := False;
            Snapshot.Recent_Project := Null_Unbounded_String;
            Snapshot.Quick_Open_Scope := Null_Unbounded_String;
            Snapshot.Quick_Open_Filter := Workspace_Quick_Open_All_Files;
            Snapshot.Feature_Panel_Visible := False;
            Snapshot.Active_Feature_Panel := Workspace_Outline_Feature;
            Add_Diagnostic
              (Snapshot, Malformed_Line, 0,
               "continuity section is not in canonical order or is incomplete");
            Mark_Partial (Partial);
         else
            Snapshot.Has_Recent_Project := Continuity_Has_Recent_Value;
            Snapshot.Recent_Project :=
              (if Continuity_Has_Recent_Value
               then Continuity_Recent_Value
               else Null_Unbounded_String);
            Snapshot.Quick_Open_Scope := Continuity_Quick_Open_Value;
            Snapshot.Quick_Open_Filter := Continuity_Quick_Filter_Value;
            Snapshot.Feature_Panel_Visible := Continuity_Feature_Visible_Value;
            Snapshot.Active_Feature_Panel := Continuity_Active_Feature_Value;
         end if;
      end if;

      if Header
        and then Snapshot.Has_Active
        and then not Has_Open_File_Path (Snapshot, To_String (Snapshot.Active_Path))
      then
         Add_Diagnostic
           (Snapshot, Invalid_Path, 0,
            "active file is not present in open-files");
         Snapshot.Has_Active := False;
         Snapshot.Active_Path := Null_Unbounded_String;
         Snapshot.Active_Rel := True;
         Mark_Partial (Partial);
      end if;

      if not Header then
         Add_Diagnostic (Snapshot, Malformed_Line, 0, "missing workspace version header");
         Status := Workspace_Persistence_Invalid_Format;
      elsif Partial = Workspace_Persistence_Partial_Restore then
         Status := Workspace_Persistence_Partial_Restore;
      else
         Status := Workspace_Persistence_Ok;
      end if;
   exception
      when Ada.Text_IO.Name_Error =>
         Status := Workspace_Persistence_Not_Found;
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         Status := Workspace_Persistence_Read_Error;
   end Load_From_File;


end Editor.Workspace_Persistence.Parsing;
