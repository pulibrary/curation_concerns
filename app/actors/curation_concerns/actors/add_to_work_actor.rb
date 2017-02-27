module CurationConcerns
  module Actors
    class AddToWorkActor < AbstractActor
      def initialize(curation_concern, user, next_actor)
        @ability = ::Ability.new(user)
        @curation_concern = curation_concern
        @next_actor = next_actor
      end

      def create(attributes)
        work_ids = attributes.delete(:in_works_ids)
        next_actor.create(attributes) && add_to_works(work_ids)
      end

      def update(attributes)
        work_ids = attributes.delete(:in_works_ids)
        add_to_works(work_ids) && next_actor.update(attributes)
      end

      private

        def add_to_works(new_work_ids)
          return true if new_work_ids.nil?
          (curation_concern.in_works_ids - new_work_ids).each do |old_id|
            work = ::ActiveFedora::Base.find(old_id)
            work.ordered_members.delete(curation_concern)
            work.members.delete(curation_concern)
            work.save
          end

          # add to new so long as the depositor for the parent and child matches, otherwise inject an error
          (new_work_ids - curation_concern.in_works_ids).each do |work_id|
            work = ::ActiveFedora::Base.find(work_id)
            if @ability.can_edit_both_works?(curation_concern, work)
              work.ordered_members << curation_concern
              work.save
            else
              curation_concern.errors[:in_works_ids] << "Works can only be related to each other if they were deposited by the same user."
            end
          end
          curation_concern.errors[:in_works_ids].empty?
        end
    end
  end
end
