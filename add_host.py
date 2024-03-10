import yaml
import click
import sys

@click.command()
@click.argument('new_host_name')
@click.option('--connection-type', default='local', help='Connection type for the new host')
@click.option('--release-dir', default='{{ansible_env.HOME}}/releases', help='Local release directory for the new host')
@click.option('--inventory-file', default='your_inventory_file.yml', help='Path to the inventory file')
@click.option('--groups', default='all', help='Specify the groups to add the new host to, comma-separated')
@click.option('--stdout', is_flag=True, help='Output to stdout instead of writing to a file')
def add_host_to_inventory(new_host_name, connection_type, release_dir, inventory_file, groups, stdout):
    with open(inventory_file, 'r') as file:
        inventory_data = yaml.safe_load(file)

    inventory_data['all']['hosts'][new_host_name] = {
        'ansible_connection': connection_type,
        'local_release_dir': release_dir
    }

    groups_list = groups.split(',')

    # Add the new host to every group
    for group in groups_list:
        if group == "all": continue
        if group == "k8s_cluster": continue
        if group not in inventory_data:
            click.echo(f"Group '{group}' does not exist in the inventory file.")
            sys.exit(1)
        if isinstance(inventory_data[group], dict) and 'hosts' in inventory_data[group]:
            inventory_data[group]['hosts'][new_host_name] = None

    if stdout:
        yaml.dump(inventory_data, sys.stdout,sort_keys=False)
    else:
        with open(inventory_file, 'w') as file:
            yaml.dump(inventory_data, file,sort_keys=False)

    if not stdout:
        print(f"{new_host_name} added to every group in the inventory file.")

if __name__ == "__main__":
    add_host_to_inventory()
