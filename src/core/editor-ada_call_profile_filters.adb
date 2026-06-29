with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Call_Profile_Filters is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Call_Candidates.Call_Candidate_Id;
   use type Editor.Ada_Call_Candidates.Call_Candidate_Status;
   use type Editor.Ada_Call_Profile_Shapes.Actual_Profile_Id;
   use type Editor.Ada_Call_Profile_Shapes.Actual_Profile_Status;
   use type Editor.Ada_Call_Profile_Shapes.Callable_Profile_Id;
   use type Editor.Ada_Call_Profile_Shapes.Callable_Profile_Status;
   use type Editor.Ada_Direct_Visibility.Declaration_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   procedure Mix (Model : in out Profile_Filter_Model; Value : Natural) is
   begin
      Model.Result_Fingerprint :=
        (Model.Result_Fingerprint * 65599 + Value + 211) mod Natural'Last;
   end Mix;

   function Empty_Filter return Profile_Filter_Info is
   begin
      return (Id => No_Profile_Filter,
              Candidate => Editor.Ada_Call_Candidates.No_Call_Candidate,
              Call_Node => Editor.Ada_Syntax_Tree.No_Node,
              Declaration => Editor.Ada_Direct_Visibility.No_Declaration,
              Actual_Profile => Editor.Ada_Call_Profile_Shapes.No_Actual_Profile,
              Callable_Profile => Editor.Ada_Call_Profile_Shapes.No_Callable_Profile,
              Formal_Count => 0,
              Positional_Count => 0,
              Named_Count => 0,
              Total_Actual_Count => 0,
              Required_Formal_Count => 0,
              Matched_Named_Count => 0,
              Unknown_Named_Count => 0,
              Defaulted_Formal_Count => 0,
              Status => Profile_Filter_Not_Checked,
              Start_Line => 1,
              End_Line => 1,
              Fingerprint => 0);
   end Empty_Filter;

   function Is_Compatible_Status (Status : Profile_Filter_Status) return Boolean is
   begin
      return Status = Profile_Filter_Arity_Compatible
        or else Status = Profile_Filter_Formal_Name_Compatible;
   end Is_Compatible_Status;


   function Contains_Name (List : String; Name : String) return Boolean is
      First : Natural := List'First;
   begin
      if List = "" or else Name = "" then
         return False;
      end if;
      for I in List'Range loop
         if List (I) = '|' then
            if I > First and then List (First .. I - 1) = Name then
               return True;
            end if;
            First := I + 1;
         end if;
      end loop;
      return First <= List'Last and then List (First .. List'Last) = Name;
   end Contains_Name;

   procedure Count_Named_Matches
     (Actual_Names  : String;
      Formal_Names  : String;
      Matched       : out Natural;
      Unknown       : out Natural)
   is
      First : Natural := Actual_Names'First;

      procedure Add_Name (F : Natural; L : Natural) is
         Name : constant String := Actual_Names (F .. L);
      begin
         if Name = "" then
            Unknown := Unknown + 1;
         elsif Contains_Name (Formal_Names, Name) then
            Matched := Matched + 1;
         else
            Unknown := Unknown + 1;
         end if;
      end Add_Name;
   begin
      Matched := 0;
      Unknown := 0;
      if Actual_Names = "" then
         return;
      end if;
      for I in Actual_Names'Range loop
         if Actual_Names (I) = '|' then
            if I > First then
               Add_Name (First, I - 1);
            else
               Unknown := Unknown + 1;
            end if;
            First := I + 1;
         end if;
      end loop;
      if First <= Actual_Names'Last then
         Add_Name (First, Actual_Names'Last);
      end if;
   end Count_Named_Matches;

   function Required_Formal_Count
     (Callable : Editor.Ada_Call_Profile_Shapes.Callable_Profile_Info) return Natural is
   begin
      if Callable.Defaulted_Parameter_Count >= Callable.Parameter_Count then
         return 0;
      end if;
      return Callable.Parameter_Count - Callable.Defaulted_Parameter_Count;
   end Required_Formal_Count;

   function Classify
     (Candidate : Editor.Ada_Call_Candidates.Call_Candidate_Info;
      Actual    : Editor.Ada_Call_Profile_Shapes.Actual_Profile_Info;
      Callable  : Editor.Ada_Call_Profile_Shapes.Callable_Profile_Info;
      Matched_Named : Natural;
      Unknown_Named : Natural;
      Required_Count : Natural)
      return Profile_Filter_Status
   is
   begin
      if Candidate.Status /= Editor.Ada_Call_Candidates.Call_Candidate_Found
        or else Candidate.Declaration = Editor.Ada_Direct_Visibility.No_Declaration
      then
         return Profile_Filter_Candidate_Unresolved;
      elsif Callable.Id = Editor.Ada_Call_Profile_Shapes.No_Callable_Profile then
         return Profile_Filter_No_Callable_Profile;
      elsif Actual.Id = Editor.Ada_Call_Profile_Shapes.No_Actual_Profile then
         if Required_Count = 0 then
            return Profile_Filter_Arity_Compatible;
         else
            return Profile_Filter_No_Actual_Profile;
         end if;
      elsif Actual.Status = Editor.Ada_Call_Profile_Shapes.Actual_Profile_Malformed then
         return Profile_Filter_Actual_Profile_Malformed;
      elsif Callable.Status = Editor.Ada_Call_Profile_Shapes.Callable_Profile_Malformed then
         return Profile_Filter_Callable_Profile_Malformed;
      elsif Actual.Total_Actual_Count > Callable.Parameter_Count then
         return Profile_Filter_Too_Many_Actuals;
      elsif Unknown_Named > 0 then
         return Profile_Filter_Unknown_Named_Actual;
      elsif Actual.Total_Actual_Count < Required_Count then
         return Profile_Filter_Missing_Required_Formal;
      elsif Actual.Named_Count > 0 and then Matched_Named = Actual.Named_Count then
         return Profile_Filter_Formal_Name_Compatible;
      else
         return Profile_Filter_Arity_Compatible;
      end if;
   end Classify;

   procedure Add_Filter
     (Model      : in out Profile_Filter_Model;
      Candidate  : Editor.Ada_Call_Candidates.Call_Candidate_Info;
      Actual     : Editor.Ada_Call_Profile_Shapes.Actual_Profile_Info;
      Callable   : Editor.Ada_Call_Profile_Shapes.Callable_Profile_Info)
   is
      Id     : constant Profile_Filter_Id :=
        Profile_Filter_Id (Natural (Model.Filters.Length) + 1);
      Matched_Named : Natural := 0;
      Unknown_Named : Natural := 0;
      Required_Count : constant Natural := Required_Formal_Count (Callable);
      Info   : Profile_Filter_Info;
      Status : Profile_Filter_Status;
   begin
      Count_Named_Matches
        (To_String (Actual.Named_Actual_Names),
         To_String (Callable.Formal_Names),
         Matched_Named,
         Unknown_Named);
      Status := Classify
        (Candidate, Actual, Callable, Matched_Named, Unknown_Named,
         Required_Count);
      Info.Id := Id;
      Info.Candidate := Candidate.Id;
      Info.Call_Node := Candidate.Node;
      Info.Declaration := Candidate.Declaration;
      Info.Actual_Profile := Actual.Id;
      Info.Callable_Profile := Callable.Id;
      Info.Formal_Count := Callable.Parameter_Count;
      Info.Positional_Count := Actual.Positional_Count;
      Info.Named_Count := Actual.Named_Count;
      Info.Total_Actual_Count := Actual.Total_Actual_Count;
      Info.Required_Formal_Count := Required_Count;
      Info.Matched_Named_Count := Matched_Named;
      Info.Unknown_Named_Count := Unknown_Named;
      Info.Defaulted_Formal_Count := Callable.Defaulted_Parameter_Count;
      Info.Status := Status;
      Info.Start_Line := Candidate.Start_Line;
      Info.End_Line := Candidate.End_Line;
      Info.Fingerprint :=
        (Profile_Filter_Status'Pos (Status) * 1000003
         + Natural (Candidate.Id) * 1009
         + Natural (Candidate.Node) * 503
         + Natural (Candidate.Declaration) * 211
         + Natural (Actual.Id) * 97
         + Natural (Callable.Id) * 53
         + Callable.Parameter_Count * 31
         + Actual.Total_Actual_Count * 17
         + Actual.Named_Count * 13
         + Required_Count * 11
         + Matched_Named * 7
         + Unknown_Named * 5
         + Callable.Defaulted_Parameter_Count * 3) mod Natural'Last;
      Model.Filters.Append (Info);
      Mix (Model, Info.Fingerprint);
   end Add_Filter;

   procedure Clear (Model : in out Profile_Filter_Model) is
   begin
      Model.Filters.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Candidates : Editor.Ada_Call_Candidates.Call_Candidate_Model;
      Shapes     : Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model)
      return Profile_Filter_Model
   is
      Model : Profile_Filter_Model;
   begin
      Clear (Model);
      for Index in 1 .. Editor.Ada_Call_Candidates.Call_Candidate_Count (Candidates) loop
         declare
            Candidate : constant Editor.Ada_Call_Candidates.Call_Candidate_Info :=
              Editor.Ada_Call_Candidates.Call_Candidate_At (Candidates, Index);
            Actual : constant Editor.Ada_Call_Profile_Shapes.Actual_Profile_Info :=
              Editor.Ada_Call_Profile_Shapes.Actual_Profile_For_Node
                (Shapes, Candidate.Node);
            Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
              Editor.Ada_Direct_Visibility.Declaration
                (Visibility, Candidate.Declaration);
            Callable : constant Editor.Ada_Call_Profile_Shapes.Callable_Profile_Info :=
              Editor.Ada_Call_Profile_Shapes.Callable_Profile_For_Node
                (Shapes, Decl.Node);
         begin
            Add_Filter (Model, Candidate, Actual, Callable);
         end;
      end loop;
      Mix (Model, Editor.Ada_Call_Candidates.Fingerprint (Candidates));
      Mix (Model, Editor.Ada_Call_Profile_Shapes.Fingerprint (Shapes));
      Mix (Model, Editor.Ada_Direct_Visibility.Fingerprint (Visibility));
      return Model;
   end Build;

   function Has_Profile_Filters (Model : Profile_Filter_Model) return Boolean is
   begin
      return not Model.Filters.Is_Empty;
   end Has_Profile_Filters;

   function Profile_Filter_Count (Model : Profile_Filter_Model) return Natural is
   begin
      return Natural (Model.Filters.Length);
   end Profile_Filter_Count;

   function Profile_Filter_At
     (Model : Profile_Filter_Model;
      Index : Positive) return Profile_Filter_Info is
   begin
      if Index > Natural (Model.Filters.Length) then
         return Empty_Filter;
      end if;
      return Model.Filters (Index);
   end Profile_Filter_At;

   function Profile_Filter
     (Model : Profile_Filter_Model;
      Id    : Profile_Filter_Id) return Profile_Filter_Info is
   begin
      if Id = No_Profile_Filter or else Natural (Id) > Natural (Model.Filters.Length) then
         return Empty_Filter;
      end if;
      return Model.Filters (Positive (Id));
   end Profile_Filter;

   function Filter_Count_For_Node
     (Model : Profile_Filter_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Model.Filters loop
         if Info.Call_Node = Node then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Filter_Count_For_Node;

   function Filter_At_For_Node
     (Model : Profile_Filter_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id;
      Index : Positive) return Profile_Filter_Info
   is
      Count : Natural := 0;
   begin
      for Info of Model.Filters loop
         if Info.Call_Node = Node then
            Count := Count + 1;
            if Count = Index then
               return Info;
            end if;
         end if;
      end loop;
      return Empty_Filter;
   end Filter_At_For_Node;

   function Compatible_Count_For_Node
     (Model : Profile_Filter_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Model.Filters loop
         if Info.Call_Node = Node and then Is_Compatible_Status (Info.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Compatible_Count_For_Node;

   function Unknown_Named_Count_For_Node
     (Model : Profile_Filter_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Model.Filters loop
         if Info.Call_Node = Node then
            Count := Count + Info.Unknown_Named_Count;
         end if;
      end loop;
      return Count;
   end Unknown_Named_Count_For_Node;

   function Fingerprint (Model : Profile_Filter_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Call_Profile_Filters;
