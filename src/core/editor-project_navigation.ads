with Editor.State;

package Editor.Project_Navigation is

   --  side-effect-free coherence predicate for the transient
   --  project navigation surfaces.  It observes File Tree, Quick Open, and
   --  Project Search state only; it never scans the filesystem, computes
   --  matches, opens files, mutates selections, executes commands, or touches
   --  workspace/settings/recent/keybinding persistence.
   function Assert_Project_Navigation_Workflows_Coherent
     (State : Editor.State.State_Type) return Boolean;

end Editor.Project_Navigation;
