with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.File_Tree;
with Editor.Quick_Open;
with Editor.Project;
with Editor.Project_Search;

package body Editor.Project_Navigation is

   use type Editor.File_Tree.File_Tree_Node_Id;
   use type Editor.File_Tree.File_Tree_Node_Kind;
   use type Editor.Quick_Open.Quick_Open_Match_Bucket;
   use type Editor.Project_Search.Project_Search_Result_Id;

   function File_Tree_Coherent
     (Tree : Editor.File_Tree.File_Tree_State) return Boolean
   is
      Count : constant Natural := Editor.File_Tree.Node_Count (Tree);
      Row   : Editor.File_Tree.Visible_File_Tree_Row;
      Node  : Editor.File_Tree.File_Tree_Node_Summary;
   begin
      if Count = 0 then
         return Editor.File_Tree.Root (Tree) = Editor.File_Tree.No_File_Tree_Node
           and then Editor.File_Tree.Visible_Row_Count (Tree) = 0;
      end if;

      if Editor.File_Tree.Root (Tree) = Editor.File_Tree.No_File_Tree_Node then
         return False;
      end if;

      for I in 1 .. Editor.File_Tree.Visible_Row_Count (Tree) loop
         Row := Editor.File_Tree.Visible_Row (Tree, I);
         if Row.Node_Id = Editor.File_Tree.No_File_Tree_Node
           or else not Editor.File_Tree.Contains (Tree, Row.Node_Id)
         then
            return False;
         end if;
      end loop;

      for I in 1 .. Editor.File_Tree.File_Node_Count (Tree) loop
         Node := Editor.File_Tree.File_Node_At (Tree, I);
         if Node.Id = Editor.File_Tree.No_File_Tree_Node
           or else Node.Kind /= Editor.File_Tree.File_Node
           or else Length (Node.Relative_Path) = 0
           or else Length (Node.Absolute_Path) = 0
         then
            return False;
         end if;
      end loop;

      return True;
   end File_Tree_Coherent;

   function Quick_Open_Coherent
     (State   : Editor.Quick_Open.Quick_Open_State;
      Project : Editor.Project.Project_State) return Boolean
   is
      Count       : constant Natural := Editor.Quick_Open.Result_Count (State);
      Has_Project : constant Boolean := Editor.Project.Has_Project (Project);
      Item        : Editor.Quick_Open.Quick_Open_Result;

      function Known_Current_Project_File
        (Relative_Path : String;
         Absolute_Path : String) return Boolean
      is
      begin
         for I in 1 .. Editor.Project.Known_File_Count (Project) loop
            declare
               Known : constant Editor.Project.Project_File_Entry :=
                 Editor.Project.Known_File_At (Project, I);
            begin
               if To_String (Known.Relative_Path) = Relative_Path
                 and then To_String (Known.Absolute_Path) = Absolute_Path
               then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end Known_Current_Project_File;
   begin
      if Editor.Quick_Open.Selected_Result_Index (State) > Count then
         return False;
      end if;

      if not Has_Project and then Count /= 0 then
         return False;
      end if;

      for I in 1 .. Count loop
         Item := Editor.Quick_Open.Result_At (State, I);
         if Length (Item.Display_Path) = 0
           or else Length (Item.Absolute_Path) = 0
           or else Item.Match_Bucket = Editor.Quick_Open.No_Match
           or else not Known_Current_Project_File
             (To_String (Item.Display_Path), To_String (Item.Absolute_Path))
         then
            return False;
         end if;
      end loop;

      return Editor.Quick_Open.Quick_Open_File_Lifecycle_Observation_Frozen
        (State);
   end Quick_Open_Coherent;

   function Project_Search_Coherent
     (Search  : Editor.Project_Search.Project_Search_State;
      Project : Editor.Project.Project_State) return Boolean
   is
      Count       : constant Natural := Editor.Project_Search.Result_Count (Search);
      Has_Project : constant Boolean := Editor.Project.Has_Project (Project);
      Result      : Editor.Project_Search.Project_Search_Result;

      function Known_Current_Project_File
        (Relative_Path : String;
         Absolute_Path : String) return Boolean
      is
      begin
         for I in 1 .. Editor.Project.Known_File_Count (Project) loop
            declare
               Known : constant Editor.Project.Project_File_Entry :=
                 Editor.Project.Known_File_At (Project, I);
            begin
               if To_String (Known.Relative_Path) = Relative_Path
                 and then To_String (Known.Absolute_Path) = Absolute_Path
               then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end Known_Current_Project_File;
   begin
      if Editor.Project_Search.Selected_Result_Index (Search) > Count then
         return False;
      end if;

      if Count = 0 then
         if Editor.Project_Search.Selected_Result_Index (Search) /= 0
           or else Editor.Project_Search.File_Group_Count (Search) /= 0
         then
            return False;
         end if;
      elsif not Has_Project then
         return False;
      end if;

      for I in 1 .. Count loop
         Result := Editor.Project_Search.Result_At (Search, I);
         if Result.Id = Editor.Project_Search.No_Project_Search_Result
           or else Result.Row = 0
           or else Length (Result.Relative_Path) = 0
           or else Length (Result.Absolute_Path) = 0
           or else Length (Result.Line_Preview) >
             Editor.Project_Search.Max_Search_Result_Preview_Length
           or else (not Editor.Project_Search.Is_Stale (Search)
                    and then not Known_Current_Project_File
                      (To_String (Result.Relative_Path),
                       To_String (Result.Absolute_Path)))
         then
            return False;
         end if;
      end loop;

      return Editor.Project_Search.Project_Search_File_Lifecycle_Observation_Frozen
        (Search);
   end Project_Search_Coherent;

   function Assert_Project_Navigation_Workflows_Coherent
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return File_Tree_Coherent (State.File_Tree)
        and then Quick_Open_Coherent (State.Quick_Open, State.Project)
        and then Project_Search_Coherent (State.Project_Search, State.Project);
   end Assert_Project_Navigation_Workflows_Coherent;

end Editor.Project_Navigation;
