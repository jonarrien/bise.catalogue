class CreateSpecies < ActiveRecord::Migration

    def change
        create_table :species do |t|
            t.string :uri
            t.integer :species_code
            t.string :binomial_name
            t.string :valid_name
            t.string :eunis_primary_name
            t.string :synonym_for
            t.string :taxonomic_rank
            t.string :scientific_name_authorship
            t.string :scientific_name
            t.string :label
            t.string :genus
            t.string :species_group
            t.string :name_according_to_ID
            t.boolean :ignore_on_match

            t.references :taxonomy

            t.timestamps
        end
        add_index :species, :uri, :unique => true
    end

end
