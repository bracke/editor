with Ada.Command_Line;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;
with GNAT.OS_Lib;
with Editor_Tool_Common; use Editor_Tool_Common;

procedure Source_Status is
   Tool : constant String := "source_status";
   Output : constant String := "/tmp/editor_source_status.txt";
   Args : GNAT.OS_Lib.Argument_List (1 .. 2) :=
     (new String'("status"), new String'("--short"));
   Show_Full : Boolean := False;
   Only_Filter : Unbounded_String;
   Result : Captured_Command_Output;
   Text : Unbounded_String;
   Shown : Natural := 0;
   Source_Count : Natural := 0;
   Test_Count : Natural := 0;
   Tool_Count : Natural := 0;
   Doc_Count : Natural := 0;
   Project_Count : Natural := 0;
   Other_Count : Natural := 0;
   Filtered_Count : Natural := 0;
   Generated_Count : Natural := 0;
   Archive_Count : Natural := 0;
   Rename_Count : Natural := 0;
   Generated_Rename_Count : Natural := 0;
   Max_Group_Lines : constant Natural := 40;
   Source_Lines : Unbounded_String;
   Test_Lines : Unbounded_String;
   Tool_Lines : Unbounded_String;
   Doc_Lines : Unbounded_String;
   Project_Lines : Unbounded_String;
   Other_Lines : Unbounded_String;
   Rename_Lines : Unbounded_String;
   Generated_Lines : Unbounded_String;
   Archive_Lines : Unbounded_String;

   function Valid_Filter (Name : String) return Boolean is
   begin
      return Name = "renames"
        or else Name = "source"
        or else Name = "tests"
        or else Name = "tools"
        or else Name = "docs"
        or else Name = "project"
        or else Name = "other"
        or else Name = "generated"
        or else Name = "archive";
   end Valid_Filter;

   function Contains (Text, Needle : String) return Boolean is
   begin
      return Ada.Strings.Fixed.Index (Text, Needle) /= 0;
   end Contains;

   function Path_From_Status_Line (Line : String) return String is
   begin
      if Line'Length <= 3 then
         return "";
      end if;
      return Line (Line'First + 3 .. Line'Last);
   end Path_From_Status_Line;

   function Is_Rename_Line (Line : String) return Boolean is
   begin
      return Line'Length >= 2 and then Line (Line'First) = 'R';
   end Is_Rename_Line;

   function Rename_Target_Path (Path : String) return String is
      Arrow : constant Natural := Ada.Strings.Fixed.Index (Path, " -> ");
   begin
      if Arrow = 0 then
         return Path;
      else
         return Path (Arrow + 4 .. Path'Last);
      end if;
   end Rename_Target_Path;

   function Lower_Path (Path : String) return String is
      Lower : String := Path;
   begin
      for C of Lower loop
         if C in 'A' .. 'Z' then
            C := Character'Val (Character'Pos (C) + 32);
         end if;
      end loop;
      return Lower;
   end Lower_Path;

   function Archive_Only (Path : String) return Boolean is
      Lower : constant String := Lower_Path (Path);
   begin
      return Contains (Lower, "readme_pass")
        or else Contains (Lower, "docs/archive/");
   end Archive_Only;

   function Generated_Artifact (Path : String) return Boolean is
      Lower : constant String := Lower_Path (Path);
   begin
      return Contains (Lower, "/obj/")
        or else Contains (Lower, "obj/")
        or else Contains (Lower, "/bin/")
        or else Contains (Lower, "tools/bin/")
        or else Contains (Lower, "e2e_product_smoke_project")
        or else (Lower'Length >= 4
                 and then Lower (Lower'Last - 3 .. Lower'Last) = ".ali")
        or else (Lower'Length >= 2
                 and then Lower (Lower'Last - 1 .. Lower'Last) = ".o")
        or else (Lower'Length >= 2
                 and then Lower (Lower'Last - 1 .. Lower'Last) = ".a");
   end Generated_Artifact;

   function Generated_Or_Archived (Path : String) return Boolean is
   begin
      return Archive_Only (Path) or else Generated_Artifact (Path);
   end Generated_Or_Archived;

   procedure Append_Line
     (Bucket : in out Unbounded_String;
      Count  : Natural;
      Line   : String)
   is
   begin
      if Show_Full or else Count <= Max_Group_Lines then
         Append (Bucket, Line);
         Append (Bucket, ASCII.LF);
      elsif Count = Max_Group_Lines + 1 then
         Append (Bucket, "  ... more entries not shown");
         Append (Bucket, ASCII.LF);
      end if;
   end Append_Line;

   procedure Emit_Group
     (Label : String;
      Count : Natural;
      Lines : Unbounded_String)
   is
   begin
      if Length (Only_Filter) > 0
        and then To_String (Only_Filter) /= Label
      then
         return;
      end if;

      if Count = 0 then
         return;
      end if;

      Ada.Text_IO.Put_Line
        (Label & " ("
         & Ada.Strings.Fixed.Trim (Natural'Image (Count), Ada.Strings.Both)
         & (if (not Show_Full) and then Count > Max_Group_Lines
            then ", shown "
              & Ada.Strings.Fixed.Trim
                (Natural'Image (Max_Group_Lines), Ada.Strings.Both)
              & ", hidden "
              & Ada.Strings.Fixed.Trim
                (Natural'Image (Count - Max_Group_Lines), Ada.Strings.Both)
            else "")
         & ")");
      Ada.Text_IO.Put (To_String (Lines));
   end Emit_Group;

   procedure Record_Live_Line
     (Line : String;
      Path : String)
   is
      Effective_Path : constant String := Rename_Target_Path (Path);
   begin
      Shown := Shown + 1;

      if Is_Rename_Line (Line) then
         Rename_Count := Rename_Count + 1;
         Append_Line (Rename_Lines, Rename_Count, Line);
      elsif Contains (Effective_Path, "src/") then
         Source_Count := Source_Count + 1;
         Append_Line (Source_Lines, Source_Count, Line);
      elsif Contains (Effective_Path, "tests/") then
         Test_Count := Test_Count + 1;
         Append_Line (Test_Lines, Test_Count, Line);
      elsif Contains (Effective_Path, "tools/") then
         Tool_Count := Tool_Count + 1;
         Append_Line (Tool_Lines, Tool_Count, Line);
      elsif Contains (Effective_Path, "docs/") or else Contains (Effective_Path, "devdocs/") then
         Doc_Count := Doc_Count + 1;
         Append_Line (Doc_Lines, Doc_Count, Line);
      elsif Contains (Effective_Path, ".gpr")
        or else Effective_Path = "README.md"
        or else Effective_Path = ".gitignore"
      then
         Project_Count := Project_Count + 1;
         Append_Line (Project_Lines, Project_Count, Line);
      else
         Other_Count := Other_Count + 1;
         Append_Line (Other_Lines, Other_Count, Line);
      end if;
   end Record_Live_Line;

   procedure Emit_Filtered_Status (Raw : String) is
      Start : Positive := Raw'First;
      Stop  : Natural;
   begin
      while Start <= Raw'Last loop
         Stop := Start;
         while Stop <= Raw'Last and then Raw (Stop) /= ASCII.LF loop
            Stop := Stop + 1;
         end loop;

         declare
            Line : constant String := Raw (Start .. Stop - 1);
            Path : constant String := Path_From_Status_Line (Line);
         begin
            if Line'Length > 0 then
               if Generated_Or_Archived (Path) then
                  if Archive_Only (Path) then
                     Archive_Count := Archive_Count + 1;
                     Append_Line (Archive_Lines, Archive_Count, Line);
                  else
                     Generated_Count := Generated_Count + 1;
                     Append_Line (Generated_Lines, Generated_Count, Line);
                  end if;
                  if Is_Rename_Line (Line) then
                     Generated_Rename_Count := Generated_Rename_Count + 1;
                  end if;
                  Filtered_Count := Filtered_Count + 1;
               else
                  Record_Live_Line (Line, Path);
               end if;
            end if;
         end;

         Start := Stop + 1;
      end loop;
   end Emit_Filtered_Status;
begin
   declare
      Index : Natural := 1;
   begin
      while Index <= Ada.Command_Line.Argument_Count loop
         declare
            Arg : constant String := Ada.Command_Line.Argument (Index);
         begin
            if Arg = "--full" then
               Show_Full := True;
            elsif Arg = "--only" then
               if Index = Ada.Command_Line.Argument_Count then
                  Fail (Tool, "--only requires a category");
               end if;

               declare
                  Filter : constant String :=
                    Ada.Command_Line.Argument (Index + 1);
               begin
                  if not Valid_Filter (Filter) then
                     Fail (Tool, "unknown --only category: " & Filter);
                  end if;
                  Only_Filter := To_Unbounded_String (Filter);
               end;
               Index := Index + 1;
            else
               Fail (Tool, "unknown argument: " & Arg);
            end if;
         end;
         Index := Index + 1;
      end loop;
   end;

   Result := Run_Capture_Bounded ("git", Args, Output);
   if Result.Exit_Code /= 0 then
      Fail (Tool, "git status failed");
   end if;

   Text := To_Unbounded_String (Output_Text (Result));
   Emit_Filtered_Status (To_String (Text));
   if Shown = 0 and then Filtered_Count = 0 then
      Info (Tool, "no live source status entries");
   else
      Ada.Text_IO.Put_Line
        ("source_status: actionable "
         & Ada.Strings.Fixed.Trim (Natural'Image (Shown), Ada.Strings.Both)
         & ", filtered generated/archive "
         & Ada.Strings.Fixed.Trim (Natural'Image (Filtered_Count), Ada.Strings.Both)
         & " (generated "
         & Ada.Strings.Fixed.Trim (Natural'Image (Generated_Count), Ada.Strings.Both)
         & ", archive "
         & Ada.Strings.Fixed.Trim (Natural'Image (Archive_Count), Ada.Strings.Both)
         & ")"
         & ", filtered generated renames "
         & Ada.Strings.Fixed.Trim (Natural'Image (Generated_Rename_Count), Ada.Strings.Both)
         & (if Length (Only_Filter) > 0
            then ", only " & To_String (Only_Filter)
            else ""));
      Ada.Text_IO.Put_Line
        ("source_status: categories"
         & " renames="
         & Ada.Strings.Fixed.Trim (Natural'Image (Rename_Count), Ada.Strings.Both)
         & " source="
         & Ada.Strings.Fixed.Trim (Natural'Image (Source_Count), Ada.Strings.Both)
         & " tests="
         & Ada.Strings.Fixed.Trim (Natural'Image (Test_Count), Ada.Strings.Both)
         & " tools="
         & Ada.Strings.Fixed.Trim (Natural'Image (Tool_Count), Ada.Strings.Both)
         & " docs="
         & Ada.Strings.Fixed.Trim (Natural'Image (Doc_Count), Ada.Strings.Both)
         & " project="
         & Ada.Strings.Fixed.Trim (Natural'Image (Project_Count), Ada.Strings.Both)
         & " other="
         & Ada.Strings.Fixed.Trim (Natural'Image (Other_Count), Ada.Strings.Both));
      Emit_Group ("renames", Rename_Count, Rename_Lines);
      Emit_Group ("source", Source_Count, Source_Lines);
      Emit_Group ("tests", Test_Count, Test_Lines);
      Emit_Group ("tools", Tool_Count, Tool_Lines);
      Emit_Group ("docs", Doc_Count, Doc_Lines);
      Emit_Group ("project", Project_Count, Project_Lines);
      Emit_Group ("other", Other_Count, Other_Lines);
      Emit_Group ("generated", Generated_Count, Generated_Lines);
      Emit_Group ("archive", Archive_Count, Archive_Lines);
   end if;
end Source_Status;
