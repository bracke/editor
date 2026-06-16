package body Editor.Ada_Call_Resolution is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Call_Candidates.Call_Candidate_Id;
   use type Editor.Ada_Call_Candidates.Call_Candidate_Status;
   use type Editor.Ada_Call_Profile_Filters.Profile_Filter_Status;
   use type Editor.Ada_Direct_Visibility.Declaration_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   procedure Mix (Model : in out Call_Resolution_Model; Value : Natural) is
   begin
      Model.Result_Fingerprint :=
        (Model.Result_Fingerprint * 65599 + Value + 223) mod Natural'Last;
   end Mix;

   function Empty_Resolution return Call_Resolution_Info is
   begin
      return (Id => No_Call_Resolution,
              Call_Node => Editor.Ada_Syntax_Tree.No_Node,
              Candidate => Editor.Ada_Call_Candidates.No_Call_Candidate,
              Declaration => Editor.Ada_Direct_Visibility.No_Declaration,
              Candidate_Count => 0,
              Filter_Count => 0,
              Viable_Filter_Count => 0,
              Rejected_Count => 0,
              Status => Call_Resolution_Not_Checked,
              Start_Line => 1,
              End_Line => 1,
              Fingerprint => 0);
   end Empty_Resolution;

   function Is_Viable
     (Status : Editor.Ada_Call_Profile_Filters.Profile_Filter_Status)
      return Boolean is
   begin
      return Status = Editor.Ada_Call_Profile_Filters.Profile_Filter_Arity_Compatible
        or else Status =
          Editor.Ada_Call_Profile_Filters.Profile_Filter_Formal_Name_Compatible;
   end Is_Viable;

   function Classify
     (Candidate    : Editor.Ada_Call_Candidates.Call_Candidate_Info;
      Filter_Count : Natural;
      Viable_Count : Natural) return Call_Resolution_Status is
   begin
      if Candidate.Status = Editor.Ada_Call_Candidates.Call_Candidate_No_Call_Name then
         return Call_Resolution_Missing_Call_Name;
      elsif Candidate.Status = Editor.Ada_Call_Candidates.Call_Candidate_No_Candidates then
         return Call_Resolution_Unresolved_Name;
      elsif Candidate.Status = Editor.Ada_Call_Candidates.Call_Candidate_Ambiguous then
         return Call_Resolution_Ambiguous_Pre_Profile;
      elsif Filter_Count = 0 then
         return Call_Resolution_No_Actual_Filter;
      elsif Viable_Count = 0 then
         return Call_Resolution_No_Viable_Profile;
      elsif Viable_Count = 1 then
         return Call_Resolution_Unique_Profile_Match;
      else
         return Call_Resolution_Ambiguous_Profile_Match;
      end if;
   end Classify;

   procedure Add_Resolution
     (Model     : in out Call_Resolution_Model;
      Candidate : Editor.Ada_Call_Candidates.Call_Candidate_Info;
      Filters   : Editor.Ada_Call_Profile_Filters.Profile_Filter_Model)
   is
      Id : constant Call_Resolution_Id :=
        Call_Resolution_Id (Natural (Model.Resolutions.Length) + 1);
      Filter_Count : constant Natural :=
        Editor.Ada_Call_Profile_Filters.Filter_Count_For_Node
          (Filters, Candidate.Node);
      Viable_Count : constant Natural :=
        Editor.Ada_Call_Profile_Filters.Compatible_Count_For_Node
          (Filters, Candidate.Node);
      Info : Call_Resolution_Info;
      Status : constant Call_Resolution_Status :=
        Classify (Candidate, Filter_Count, Viable_Count);
   begin
      Info.Id := Id;
      Info.Call_Node := Candidate.Node;
      Info.Candidate := Candidate.Id;
      Info.Declaration := Candidate.Declaration;
      Info.Candidate_Count := Candidate.Candidate_Count;
      Info.Filter_Count := Filter_Count;
      Info.Viable_Filter_Count := Viable_Count;
      if Filter_Count > Viable_Count then
         Info.Rejected_Count := Filter_Count - Viable_Count;
      else
         Info.Rejected_Count := 0;
      end if;
      Info.Status := Status;
      Info.Start_Line := Candidate.Start_Line;
      Info.End_Line := Candidate.End_Line;
      Info.Fingerprint :=
        (Call_Resolution_Status'Pos (Status) * 1000003
         + Natural (Candidate.Id) * 1009
         + Natural (Candidate.Node) * 503
         + Natural (Candidate.Declaration) * 211
         + Candidate.Candidate_Count * 97
         + Filter_Count * 53
         + Viable_Count * 31
         + Info.Rejected_Count * 17) mod Natural'Last;
      Model.Resolutions.Append (Info);
      Mix (Model, Info.Fingerprint);
   end Add_Resolution;

   procedure Clear (Model : in out Call_Resolution_Model) is
   begin
      Model.Resolutions.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Candidates : Editor.Ada_Call_Candidates.Call_Candidate_Model;
      Filters    : Editor.Ada_Call_Profile_Filters.Profile_Filter_Model)
      return Call_Resolution_Model
   is
      Model : Call_Resolution_Model;
   begin
      Clear (Model);
      for Index in 1 .. Editor.Ada_Call_Candidates.Call_Candidate_Count (Candidates) loop
         Add_Resolution
           (Model,
            Editor.Ada_Call_Candidates.Call_Candidate_At (Candidates, Index),
            Filters);
      end loop;
      Mix (Model, Editor.Ada_Call_Candidates.Fingerprint (Candidates));
      Mix (Model, Editor.Ada_Call_Profile_Filters.Fingerprint (Filters));
      return Model;
   end Build;

   function Has_Call_Resolutions (Model : Call_Resolution_Model) return Boolean is
   begin
      return not Model.Resolutions.Is_Empty;
   end Has_Call_Resolutions;

   function Call_Resolution_Count (Model : Call_Resolution_Model) return Natural is
   begin
      return Natural (Model.Resolutions.Length);
   end Call_Resolution_Count;

   function Call_Resolution_At
     (Model : Call_Resolution_Model;
      Index : Positive) return Call_Resolution_Info is
   begin
      if Index > Natural (Model.Resolutions.Length) then
         return Empty_Resolution;
      end if;
      return Model.Resolutions (Index);
   end Call_Resolution_At;

   function Call_Resolution
     (Model : Call_Resolution_Model;
      Id    : Call_Resolution_Id) return Call_Resolution_Info is
   begin
      if Id = No_Call_Resolution
        or else Natural (Id) > Natural (Model.Resolutions.Length)
      then
         return Empty_Resolution;
      end if;
      return Model.Resolutions (Positive (Id));
   end Call_Resolution;

   function Resolution_For_Node
     (Model : Call_Resolution_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Call_Resolution_Info is
   begin
      for Info of Model.Resolutions loop
         if Info.Call_Node = Node then
            return Info;
         end if;
      end loop;
      return Empty_Resolution;
   end Resolution_For_Node;

   function Count_Status
     (Model  : Call_Resolution_Model;
      Status : Call_Resolution_Status) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Model.Resolutions loop
         if Info.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Fingerprint (Model : Call_Resolution_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Call_Resolution;
